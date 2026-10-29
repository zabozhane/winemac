import XCTest
@testable import WinemacCore

final class BottleRemovalTests: XCTestCase {
    func testRemovingOneGameNeverRunsUninstall() {
        for name in ["l2", "lineage-2-client", "uninstall"] {
            XCTAssertEqual(BottleRemoval.arguments(forBottle: name), ["remove", name])
        }
    }
}
