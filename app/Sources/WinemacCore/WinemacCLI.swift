import Foundation

public enum WinemacCLIError: LocalizedError {
    case launcherNotFound(URL)

    public var errorDescription: String? {
        switch self {
        case .launcherNotFound(let url):
            return "Не найден лаунчер \(url.path). Приложение должно лежать в папке winemac рядом с bin/."
        }
    }
}

/// Entry point to bin/winemac. The app never reimplements launcher logic: every action is a CLI command.
public struct WinemacCLI {
    public let rootURL: URL
    public let launcherURL: URL

    public init(rootURL: URL) throws {
        let launcherURL = rootURL.appendingPathComponent("bin/winemac")
        guard FileManager.default.isExecutableFile(atPath: launcherURL.path) else {
            throw WinemacCLIError.launcherNotFound(launcherURL)
        }
        self.rootURL = rootURL
        self.launcherURL = launcherURL
    }

    public func logURL(forBottle name: String) -> URL {
        rootURL.appendingPathComponent("logs/\(name).log")
    }

    /// Starts a command and returns immediately; read `lines` for live output.
    public func start(_ arguments: [String]) throws -> CLIProcess {
        try CLIProcess(launcherURL: launcherURL, arguments: arguments)
    }

    /// Runs a command to completion and returns all of its output.
    public func run(_ arguments: [String]) async throws -> CommandResult {
        let process = try start(arguments)
        var lines: [String] = []
        for await line in process.lines {
            lines.append(line)
        }
        let exitCode = await process.waitForExit()
        return CommandResult(lines: lines, exitCode: exitCode)
    }
}

public struct CommandResult {
    public let lines: [String]
    public let exitCode: Int32

    public var succeeded: Bool { exitCode == 0 }
}

/// One running bin/winemac invocation. stdout and stderr are merged, as the user would see them in a terminal.
public final class CLIProcess {
    public let lines: AsyncStream<String>
    private let process = Process()
    private let inputPipe = Pipe()

    init(launcherURL: URL, arguments: [String]) throws {
        let outputPipe = Pipe()
        process.executableURL = launcherURL
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        process.standardInput = inputPipe

        let (lines, continuation) = AsyncStream.makeStream(of: String.self)
        self.lines = lines
        var splitter = LineSplitter()
        // The handler is called serially for one file handle, so the splitter needs no lock.
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            if chunk.isEmpty {
                handle.readabilityHandler = nil
                if let last = splitter.finish() { continuation.yield(last) }
                continuation.finish()
                return
            }
            splitter.feed(chunk).forEach { continuation.yield($0) }
        }
        try process.run()
    }

    /// Answers a prompt of the command, e.g. the confirmation of `remove`.
    public func send(_ text: String) {
        inputPipe.fileHandleForWriting.write(Data(text.utf8))
    }

    public func waitForExit() async -> Int32 {
        let process = self.process
        return await Task.detached {
            process.waitUntilExit()
            return process.terminationStatus
        }.value
    }
}
