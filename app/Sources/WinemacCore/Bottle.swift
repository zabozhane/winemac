import Foundation

public struct Bottle: Identifiable, Equatable {
    public let name: String
    /// Path of the imported exe relative to drive_c; nil until `winemac import` has run.
    public let executablePath: String?

    public var id: String { name }

    public init(name: String, executablePath: String?) {
        self.name = name
        self.executablePath = executablePath
    }

    /// Parses `winemac list`, which prints "<bottle>  <exe>" per line and "-" when nothing is imported.
    public static func parseList(_ lines: [String]) -> [Bottle] {
        lines.compactMap { line in
            guard let separator = line.range(of: "  ") else { return nil }
            let name = String(line[..<separator.lowerBound])
            let executable = line[separator.upperBound...].trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return nil }
            return Bottle(name: name, executablePath: executable == "-" ? nil : executable)
        }
    }
}
