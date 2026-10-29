import XCTest
@testable import WinemacCore

final class RendererTests: XCTestCase {
    func testParsesCliValues() {
        XCTAssertEqual(Renderer.parse(["vulkan"]), .vulkan)
        XCTAssertEqual(Renderer.parse(["gl", ""]), .openGL)
    }

    func testRejectsUnknownValue() {
        XCTAssertNil(Renderer.parse(["gdi"]))
        XCTAssertNil(Renderer.parse([]))
    }
}
