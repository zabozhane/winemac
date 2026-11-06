import XCTest
@testable import WinemacCore

final class DisplayModeTests: XCTestCase {
    func testParsesCliValues() {
        XCTAssertEqual(DisplayMode.parse(["window 1600x1000"]), .window)
        XCTAssertEqual(DisplayMode.parse(["fullscreen", ""]), .fullscreen)
    }

    func testRejectsUnknownValue() {
        XCTAssertNil(DisplayMode.parse(["borderless"]))
        XCTAssertNil(DisplayMode.parse([]))
    }
}
