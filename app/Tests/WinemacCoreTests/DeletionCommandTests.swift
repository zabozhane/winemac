import XCTest
@testable import WinemacCore

final class DeletionCommandTests: XCTestCase {
    func testRemovingOneGameNeverRunsUninstall() {
        for name in ["l2", "lineage-2-client", "uninstall"] {
            let arguments = DeletionCommand.removeBottle(name).arguments
            XCTAssertEqual(arguments.first, "remove")
            XCTAssertEqual(arguments, ["remove", name])
        }
    }

    func testUninstallNeedsTypedPhrase() {
        let command = DeletionCommand.uninstallEverything
        XCTAssertFalse(command.isConfirmed(byTyping: ""))
        XCTAssertFalse(command.isConfirmed(byTyping: "да"))
        XCTAssertTrue(command.isConfirmed(byTyping: " Удалить всё "))
    }

    func testRemovingOneGameNeedsNoTypedPhrase() {
        XCTAssertTrue(DeletionCommand.removeBottle("l2").isConfirmed(byTyping: ""))
    }
}
