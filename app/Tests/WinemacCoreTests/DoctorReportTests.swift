import XCTest
@testable import WinemacCore

final class DoctorReportTests: XCTestCase {
    private let failingOutput = [
        "System (macOS 15.1)",
        "  [ok]   Apple Silicon",
        "  [ok]   Rosetta 2",
        "  [FAIL] Wine runtime",
        "Bottle l2",
        "  [ok]   no links into $HOME",
        "  [FAIL] exe imported",
        "winemac: error: 2 check(s) failed",
    ]

    func testGroupsChecksBySection() {
        let report = DoctorReport.parse(failingOutput)
        XCTAssertEqual(report.sections.map(\.title), ["System (macOS 15.1)", "Bottle l2"])
        XCTAssertEqual(report.systemSection?.checks.count, 3)
        XCTAssertEqual(report.section(forBottle: "l2")?.checks, [
            .init(label: "no links into $HOME", passed: true),
            .init(label: "exe imported", passed: false),
        ])
    }

    func testCountsFailures() {
        XCTAssertEqual(DoctorReport.parse(failingOutput).failedCount, 2)
    }

    func testSummaryLineIsNotASection() {
        let report = DoctorReport.parse(["System (macOS 15.1)", "  [ok]   Homebrew", "==> All checks passed"])
        XCTAssertEqual(report.sections.count, 1)
        XCTAssertEqual(report.failedCount, 0)
    }

    func testUnknownBottleHasNoSection() {
        XCTAssertNil(DoctorReport.parse(failingOutput).section(forBottle: "other"))
    }
}
