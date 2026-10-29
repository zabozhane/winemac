import XCTest
@testable import WinemacCore

final class LineSplitterTests: XCTestCase {
    func testKeepsPartialLineUntilNextChunk() {
        var splitter = LineSplitter()
        XCTAssertEqual(splitter.feed(Data("==> Sta".utf8)), [])
        XCTAssertEqual(splitter.feed(Data("rting\nsecond\nthi".utf8)), ["==> Starting", "second"])
        XCTAssertEqual(splitter.finish(), "thi")
        XCTAssertNil(splitter.finish())
    }

    func testKeepsEmptyLines() {
        var splitter = LineSplitter()
        XCTAssertEqual(splitter.feed(Data("a\n\nb\n".utf8)), ["a", "", "b"])
        XCTAssertNil(splitter.finish())
    }

    func testDoesNotSplitMultibyteCharacterAcrossChunks() {
        var splitter = LineSplitter()
        let bytes = Array("Готово\n".utf8)
        XCTAssertEqual(splitter.feed(Data(bytes[0..<3])), [])
        XCTAssertEqual(splitter.feed(Data(bytes[3...])), ["Готово"])
    }
}
