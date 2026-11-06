import Foundation

/// How the game window starts, stored per bottle by `winemac display`.
public enum DisplayMode: String, CaseIterable, Identifiable {
    case window
    case fullscreen

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .window: "В окне"
        case .fullscreen: "Весь экран"
        }
    }

    /// Parses `winemac display <bottle>`, which prints `window <W>x<H>` or `fullscreen` as its last line.
    public static func parse(_ lines: [String]) -> DisplayMode? {
        lines.last { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .flatMap { $0.split(separator: " ").first }
            .flatMap { DisplayMode(rawValue: String($0)) }
    }
}
