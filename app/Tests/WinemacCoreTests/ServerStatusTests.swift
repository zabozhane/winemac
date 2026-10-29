import XCTest
@testable import WinemacCore

final class ServerStatusTests: XCTestCase {
    private let startingOutput = [
        "docker\tready\t",
        "mariadb\tready\t",
        "login\tstarting\t",
        "game\tfailed\texited with code 1",
        "ollama\tunavailable\tnot configured",
    ]

    func testParsesStatesAndDetails() {
        let status = ServerStatus.parse(startingOutput)
        XCTAssertEqual(status.entry(for: .login), .init(state: .starting, detail: ""))
        XCTAssertEqual(status.entry(for: .game), .init(state: .failed, detail: "exited with code 1"))
        XCTAssertEqual(status.entry(for: .ollama).detail, "not configured")
        XCTAssertTrue(status.isAttached)
        XCTAssertFalse(status.isReady)
        XCTAssertFalse(status.isStopped)
    }

    func testReadyIgnoresOllama() {
        let status = ServerStatus.parse([
            "mariadb\tready\t", "login\tready\t", "game\tready\t", "ollama\tunavailable\tnot configured",
        ])
        XCTAssertTrue(status.isReady)
    }

    func testNothingAttached() {
        let status = ServerStatus.parse(ServerStatus.Component.allCases.map { "\($0.rawValue)\tunavailable\tno server attached" })
        XCTAssertFalse(status.isAttached)
        XCTAssertTrue(status.isStopped)
    }

    func testSkipsUnknownLines() {
        let status = ServerStatus.parse(["==> Starting", "redis\tready\t", "login\tweird\t"])
        XCTAssertEqual(status.entries, [:])
        XCTAssertEqual(status.entry(for: .login).state, .unavailable)
    }
}
