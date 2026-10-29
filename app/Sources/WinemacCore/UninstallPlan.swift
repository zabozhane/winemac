import Foundation

/// What `winemac uninstall` announces before it asks for confirmation.
public struct UninstallPlan: Equatable {
    public struct Item: Equatable {
        public let size: String
        public let path: String
    }

    public var items: [Item] = []
    public var homebrewFormulae: [String] = []
    public var notTouched: String = ""

    private static let formulaePrefix = "Homebrew formulae installed by winemac:"
    /// The CLI prints this line last, right before it waits for the answer.
    public static let lastLinePrefix = "Not touched:"

    public static func isLastLine(_ line: String) -> Bool {
        line.hasPrefix(lastLinePrefix)
    }

    /// Parses the listing: `du -sh` rows ("  <size>\t<path>"), the formulae row and the "Not touched" row.
    public static func parse(_ lines: [String]) -> UninstallPlan {
        var plan = UninstallPlan()
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix(formulaePrefix) {
                plan.homebrewFormulae = trimmed.dropFirst(formulaePrefix.count)
                    .split(separator: " ").map(String.init)
            } else if isLastLine(trimmed) {
                plan.notTouched = trimmed
            } else if let tab = trimmed.firstIndex(of: "\t") {
                let size = String(trimmed[..<tab])
                let path = String(trimmed[trimmed.index(after: tab)...])
                plan.items.append(Item(size: size, path: path))
            }
        }
        return plan
    }
}
