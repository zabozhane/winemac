import Foundation

/// Direct3D backend of wined3d, stored per bottle by `winemac renderer`.
public enum Renderer: String, CaseIterable, Identifiable {
    case openGL = "gl"
    case vulkan

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .openGL: "OpenGL"
        case .vulkan: "Vulkan"
        }
    }

    /// Parses `winemac renderer <bottle>`, which prints the renderer name as its last line.
    public static func parse(_ lines: [String]) -> Renderer? {
        lines.last { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .flatMap { Renderer(rawValue: $0.trimmingCharacters(in: .whitespaces)) }
    }
}
