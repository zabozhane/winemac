import XCTest
@testable import WinemacCore

final class UninstallPlanTests: XCTestCase {
    func testParsesListingPrintedBeforeConfirmation() {
        let plan = UninstallPlan.parse([
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

    func testRecognisesLastLineOfListing() {
        XCTAssertTrue(UninstallPlan.isLastLine("Not touched: Homebrew itself"))
        XCTAssertFalse(UninstallPlan.isLastLine("This will permanently delete:"))
    }
}
