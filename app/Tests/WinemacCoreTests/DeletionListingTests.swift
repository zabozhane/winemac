import XCTest
@testable import WinemacCore

final class DeletionListingTests: XCTestCase {
    func testParsesListingPrintedBeforeConfirmation() {
        let plan = DeletionListing.parse([
            "This will permanently delete:",
            "  1.2G\t/Users/me/winemac/bottles",
            "  12K\t/Users/me/winemac/bin",
            "  Homebrew formulae installed by winemac: winetricks cabextract",
            "Not touched: Homebrew itself and Rosetta 2 (system components).",
        ])
        XCTAssertEqual(plan.items, [
            .init(size: "1.2G", path: "/Users/me/winemac/bottles"),
            .init(size: "12K", path: "/Users/me/winemac/bin"),
        ])
        XCTAssertEqual(plan.homebrewFormulae, ["winetricks", "cabextract"])
        XCTAssertEqual(plan.notTouched, "Not touched: Homebrew itself and Rosetta 2 (system components).")
    }

    func testParsesRemoveListing() {
        let listing = DeletionListing.parse([
            "This will permanently delete bottle 'l2':",
            "  2.1G\t/Users/me/winemac/bottles/l2",
            "  game inside it: C:/Games/Interlude/system/l2.exe",
            "Not touched: the Wine runtime, other bottles, the winetricks download cache.",
        ])
        XCTAssertEqual(listing.items, [.init(size: "2.1G", path: "/Users/me/winemac/bottles/l2")])
        XCTAssertTrue(listing.homebrewFormulae.isEmpty)
    }

    func testRecognisesLastLineOfListing() {
        XCTAssertTrue(DeletionListing.isLastLine("Not touched: Homebrew itself"))
        XCTAssertFalse(DeletionListing.isLastLine("This will permanently delete:"))
    }
}
