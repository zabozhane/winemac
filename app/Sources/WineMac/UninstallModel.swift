import Foundation
import Observation
import WinemacCore

/// Drives `winemac uninstall`: shows the CLI's own listing, then answers its y/N prompt.
@MainActor
@Observable
final class UninstallModel {
    enum Phase { case loading, confirming, deleting, deleted, cancelled, failed }

    private let cli: WinemacCLI
    private var process: CLIProcess?
    private var remainingLines: AsyncStream<String>.Iterator?
    private(set) var phase = Phase.loading
    private(set) var plan = UninstallPlan()
    private(set) var log: [String] = []

    init(cli: WinemacCLI) {
        self.cli = cli
    }

    func loadPlan() async {
        do {
            let process = try cli.start(["uninstall"])
            self.process = process
            var listing: [String] = []
            var iterator = process.lines.makeAsyncIterator()
            while let line = await iterator.next() {
                listing.append(line)
                if UninstallPlan.isLastLine(line) { break }
            }
            remainingLines = iterator
            log = listing
            plan = UninstallPlan.parse(listing)
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
