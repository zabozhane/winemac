import Foundation
import Observation
import WinemacCore

/// "Add game" = `create` (if the bottle is new) → `deps` → `import`, run one after another.
@MainActor
@Observable
final class AddGameModel {
    enum Step: String, Identifiable {
        case create, deps, `import`

        var id: String { rawValue }

        var title: String {
            switch self {
            case .create: "Создать изолированную бутылку"
            case .deps: "Установить зависимости"
            case .import: "Скопировать клиент в бутылку"
            }
        }
    }

    enum StepState { case pending, running, done, failed }

    static let defaultDependencies = ["d3dx9", "vcrun2005", "vcrun2008"]

    private let cli: WinemacCLI
    private let existingBottleNames: Set<String>
    var bottleName = "l2"
    private(set) var gameFolder: URL?
    private(set) var executables: [String] = []
    var selectedExecutable: String?
    var selectedDependencies = Set(defaultDependencies)
    private(set) var stepStates: [Step: StepState] = [:]
    private(set) var plannedSteps: [Step] = []
    private(set) var log: [String] = []
    private(set) var isInstalling = false
    private(set) var isFinished = false

    init(cli: WinemacCLI, existingBottleNames: Set<String>) {
        self.cli = cli
        self.existingBottleNames = existingBottleNames
    }

    var canInstall: Bool {
        !isInstalling && !bottleName.isEmpty && gameFolder != nil && selectedExecutable != nil
    }

    func chooseGameFolder(_ folder: URL) {
        gameFolder = folder
        executables = ExecutableFinder.executables(in: folder)
        selectedExecutable = executables.first
    }

    func state(of step: Step) -> StepState {
        stepStates[step] ?? .pending
    }

    func install() async {
        guard canInstall, let gameFolder, let selectedExecutable else { return }
        isInstalling = true
        defer { isInstalling = false }

        let dependencies = Self.defaultDependencies.filter(selectedDependencies.contains)
        var plan: [(Step, [String])] = []
        if !existingBottleNames.contains(bottleName) { plan.append((.create, ["create", bottleName])) }
        if !dependencies.isEmpty { plan.append((.deps, ["deps", bottleName] + dependencies)) }
        plan.append((.import, ["import", bottleName, gameFolder.path, selectedExecutable]))

        plannedSteps = plan.map(\.0)
        for (step, arguments) in plan {
            guard await run(step, arguments) else { return }
        }
        isFinished = true
    }

    private func run(_ step: Step, _ arguments: [String]) async -> Bool {
        stepStates[step] = .running
        do {
            let process = try cli.start(arguments)
            for await line in process.lines { log.append(line) }
            let succeeded = await process.waitForExit() == 0
            stepStates[step] = succeeded ? .done : .failed
            return succeeded
        } catch {
            log.append(error.localizedDescription)
            stepStates[step] = .failed
            return false
        }
    }
}
