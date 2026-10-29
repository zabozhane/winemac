import Foundation

/// Result of `winemac doctor`, grouped the way the CLI prints it: a "System" section and one per bottle.
public struct DoctorReport: Equatable {
    public struct Check: Equatable {
        public let label: String
        public let passed: Bool
    }

    public struct Section: Equatable {
        public let title: String
        public var checks: [Check]
    }

    public var sections: [Section]

    public var failedCount: Int {
        sections.reduce(0) { count, section in count + section.checks.filter { !$0.passed }.count }
    }

    public func section(forBottle name: String) -> Section? {
        sections.first { $0.title == "Bottle \(name)" }
    }

    public var systemSection: Section? {
        sections.first { $0.title.hasPrefix("System") }
    }

    private static let passedMarker = "[ok]"
    private static let failedMarker = "[FAIL]"
    // Summary lines printed after the checks, not section headers.
    private static let summaryPrefixes = ["==>", "winemac:"]

    public static func parse(_ lines: [String]) -> DoctorReport {
        var sections: [Section] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let check = parseCheck(trimmed) {
                guard !sections.isEmpty else { continue }
                sections[sections.count - 1].checks.append(check)
            } else if !trimmed.isEmpty, !line.hasPrefix(" "), !summaryPrefixes.contains(where: trimmed.hasPrefix) {
                sections.append(Section(title: trimmed, checks: []))
            }
        }
        return DoctorReport(sections: sections)
    }

    private static func parseCheck(_ line: String) -> Check? {
        for (marker, passed) in [(passedMarker, true), (failedMarker, false)] where line.hasPrefix(marker) {
            let label = line.dropFirst(marker.count).trimmingCharacters(in: .whitespaces)
            return Check(label: label, passed: passed)
        }
        return nil
    }
}
