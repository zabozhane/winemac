import Foundation
import Observation
import WinemacCore

/// State of the main window. Every action is delegated to a bin/winemac command.
@MainActor
@Observable
final class LibraryModel {
    let cli: WinemacCLI
    private(set) var bottles: [Bottle] = []
    var selectedBottleName: String?
    private(set) var doctor: DoctorReport?
    private(set) var isChecking = false
    private(set) var runningBottleName: String?
    private(set) var runStartedAt: Date?
    private(set) var renderers: [String: Renderer] = [:]
    private(set) var server: ServerStatus?
    /// True while `server up` or `server down` runs; their output goes to the log panel.
    private(set) var isChangingServer = false
    /// Output of the last command, shown in the log panel.
    private(set) var log: [String] = []
    var errorMessage: String?

    init(cli: WinemacCLI) {
        self.cli = cli
    }

    var selectedBottle: Bottle? {
        bottles.first { $0.name == selectedBottleName }
    }

    func refresh() async {
        await loadBottles()
        await checkDoctor()
    }

    func loadBottles() async {
        guard let result = await runReportingErrors(["list"]) else { return }
        bottles = Bottle.parseList(result.lines)
        if selectedBottle == nil { selectedBottleName = bottles.first?.name }
        for bottle in bottles { await loadRenderer(of: bottle) }
    }

    func loadRenderer(of bottle: Bottle) async {
        guard let result = await runReportingErrors(["renderer", bottle.name]) else { return }
        renderers[bottle.name] = Renderer.parse(result.lines)
    }

    /// Takes effect on the next launch; wined3d reads the setting when the game starts.
    func setRenderer(_ renderer: Renderer, of bottle: Bottle) async {
        guard renderers[bottle.name] != renderer else { return }
        await runReportingErrors(["renderer", bottle.name, renderer.rawValue])
        await loadRenderer(of: bottle)
    }

    func checkDoctor() async {
        isChecking = true
        defer { isChecking = false }
        // doctor exits with an error when a check fails; the report itself is what we show.
        guard let result = await runReportingErrors(["doctor"], failOnExitCode: false) else { return }
        doctor = DoctorReport.parse(result.lines)
    }

    func play(_ bottle: Bottle) async {
        guard runningBottleName == nil else { return }
        log = []
        runningBottleName = bottle.name
        runStartedAt = .now
        defer {
            runningBottleName = nil
            runStartedAt = nil
        }
        do {
            // `run` stays alive until the game exits, so the window shows "running" exactly as long.
            let process = try cli.start(["run", bottle.name])
            for await line in process.lines { log.append(line) }
            let exitCode = await process.waitForExit()
            if exitCode != 0 { errorMessage = "Игра завершилась с кодом \(exitCode). Подробности в логе." }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stop(_ bottle: Bottle) async {
        await runReportingErrors(["stop", bottle.name])
    }

    func refreshServer() async {
        // Polled in the background: a failing status call must not raise an alert every few seconds.
        guard let result = try? await cli.run(["server", "status"]) else { return }
        server = ServerStatus.parse(result.lines)
    }

    func startServer() async {
        await changeServer("up")
    }

    func stopServer() async {
        await changeServer("down")
    }

    private func changeServer(_ command: String) async {
        guard !isChangingServer else { return }
        isChangingServer = true
        defer { isChangingServer = false }
        log = []
        do {
            let process = try cli.start(["server", command])
            for await line in process.lines { log.append(line) }
            if await process.waitForExit() != 0 {
                errorMessage = log.last ?? "winemac server \(command) завершился с ошибкой"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        await refreshServer()
    }

    func audit() async {
        guard let result = await runReportingErrors(["audit"]) else { return }
        log = result.lines
    }

    @discardableResult
    private func runReportingErrors(_ arguments: [String], failOnExitCode: Bool = true) async -> CommandResult? {
        do {
            let result = try await cli.run(arguments)
            if failOnExitCode, !result.succeeded {
                errorMessage = result.lines.last ?? "winemac \(arguments.joined(separator: " ")): код \(result.exitCode)"
                return nil
            }
            return result
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
