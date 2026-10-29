import Foundation
import Observation
import WinemacCore

/// Drives a deleting CLI command (`uninstall`, `remove <bottle>`): shows its own listing, then answers its y/N prompt.
@MainActor
@Observable
final class DeletionModel: Identifiable {
    enum Phase { case loading, confirming, deleting, deleted, cancelled, failed }

    private let cli: WinemacCLI
    private let arguments: [String]
    private var process: CLIProcess?
    private var remainingLines: AsyncStream<String>.Iterator?
    private(set) var phase = Phase.loading
    /// What the command printed before asking for confirmation.
    private(set) var listing: [String] = []
    private(set) var log: [String] = []

    init(cli: WinemacCLI, arguments: [String]) {
        self.cli = cli
        self.arguments = arguments
    }

    var plan: UninstallPlan { UninstallPlan.parse(listing) }

    func loadListing() async {
        do {
            let process = try cli.start(arguments)
            self.process = process
            var iterator = process.lines.makeAsyncIterator()
            while let line = await iterator.next() {
                listing.append(line)
                if UninstallPlan.isLastLine(line) { break }
            }
            remainingLines = iterator
            log = listing
            phase = .confirming
        } catch {
            log = [error.localizedDescription]
            phase = .failed
        }
    }

    func confirm() async {
        await answer("y\n", nextPhase: .deleting)
    }

    func cancel() async {
        await answer("n\n", nextPhase: .cancelled)
    }

    private func answer(_ text: String, nextPhase: Phase) async {
        guard phase == .confirming, let process, var iterator = remainingLines else { return }
        phase = nextPhase
        process.send(text)
        while let line = await iterator.next() { log.append(line) }
        let exitCode = await process.waitForExit()
        if nextPhase == .deleting { phase = exitCode == 0 ? .deleted : .failed }
    }
}
