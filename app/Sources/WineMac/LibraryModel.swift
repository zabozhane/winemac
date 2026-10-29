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
