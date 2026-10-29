import Foundation
import Observation
import WinemacCore

/// Drives `winemac remove <bottle>`: shows the CLI's own listing, then answers its y/N prompt.
@MainActor
@Observable
final class RemoveBottleModel: Identifiable {
    enum Phase { case loading, confirming, deleting, deleted, cancelled, failed }

    private let cli: WinemacCLI
    let bottleName: String
    private var process: CLIProcess?
    private var remainingLines: AsyncStream<String>.Iterator?
    private(set) var phase = Phase.loading
    /// What the command printed before asking for confirmation.
    private(set) var listing: [String] = []
    private(set) var log: [String] = []

    init(cli: WinemacCLI, bottleName: String) {
        self.cli = cli
        self.bottleName = bottleName
    }

    var parsedListing: DeletionListing { DeletionListing.parse(listing) }

    func loadListing() async {
        do {
            let process = try cli.start(BottleRemoval.arguments(forBottle: bottleName))
            self.process = process
            var iterator = process.lines.makeAsyncIterator()
            while let line = await iterator.next() {
                listing.append(line)
                if DeletionListing.isLastLine(line) { break }
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
