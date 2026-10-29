import Foundation

/// Lists .exe files in a game folder so the user picks one instead of typing a path for `winemac import`.
public enum ExecutableFinder {
    /// Game clients keep their exe at the top level or one folder down (L2: system/l2.exe).
    public static let maximumDepth = 2

    /// Returns paths relative to `folder`, sorted, using "/" as the separator.
    public static func executables(in folder: URL) -> [String] {
        let root = folder.standardizedFileURL.resolvingSymlinksInPath()
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var found: [String] = []
        for case let url as URL in enumerator {
            if enumerator.level > maximumDepth {
                enumerator.skipDescendants()
                continue
            }
            guard url.pathExtension.lowercased() == "exe",
                  (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
            else { continue }
            found.append(relativePath(of: url, to: root))
        }
        return found.sorted()
    }

    private static func relativePath(of url: URL, to root: URL) -> String {
        let fileComponents = url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
        return fileComponents.dropFirst(root.pathComponents.count).joined(separator: "/")
    }
}
