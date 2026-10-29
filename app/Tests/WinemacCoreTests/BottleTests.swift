import XCTest
@testable import WinemacCore

final class BottleTests: XCTestCase {
    func testParsesImportedAndEmptyBottles() {
        let bottles = Bottle.parseList([
            "l2  Games/Interlude/system/l2.exe",
            "test  -",
        ])
        XCTAssertEqual(bottles, [
            Bottle(name: "l2", executablePath: "Games/Interlude/system/l2.exe"),
            Bottle(name: "test", executablePath: nil),
        ])
    }

    func testKeepsSpacesInsideExecutablePath() {
        let bottles = Bottle.parseList(["l2  Games/Lineage II/system/l2.exe"])
        XCTAssertEqual(bottles.first?.executablePath, "Games/Lineage II/system/l2.exe")
    }

    func testIgnoresBlankOutput() {
        XCTAssertEqual(Bottle.parseList([""]), [])
    }
}
