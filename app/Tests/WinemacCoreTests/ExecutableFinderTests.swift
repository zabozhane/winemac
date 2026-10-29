import XCTest
@testable import WinemacCore

final class ExecutableFinderTests: XCTestCase {
    private var folder: URL!

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        for path in ["L2.exe", "system/l2.exe", "system/readme.txt", "system/deep/nested/tool.exe", "Tools/Patch.EXE"] {
            let url = folder.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data().write(to: url)
        }
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: folder)
    }

    func testFindsExecutablesUpToTwoLevelsCaseInsensitively() {
        XCTAssertEqual(ExecutableFinder.executables(in: folder), ["L2.exe", "Tools/Patch.EXE", "system/l2.exe"])
    }

    func testReturnsEmptyListForMissingFolder() {
        XCTAssertEqual(ExecutableFinder.executables(in: folder.appendingPathComponent("missing")), [])
    }
}
