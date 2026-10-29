import Foundation

/// The two destructive CLI commands the app can run. Kept as one type so the per-game button
/// can only ever build `remove <bottle>`, never `uninstall`.
public enum DeletionCommand: Equatable {
    case removeBottle(String)
    case uninstallEverything

    public var arguments: [String] {
        switch self {
        case .removeBottle(let name): ["remove", name]
        case .uninstallEverything: ["uninstall"]
        }
    }

    /// Text the user has to type before a full uninstall; deleting one game needs only a click.
    public var confirmationPhrase: String? {
        switch self {
        case .removeBottle: nil
        case .uninstallEverything: "удалить всё"
        }
    }

    public func isConfirmed(byTyping text: String) -> Bool {
        guard let confirmationPhrase else { return true }
        return text.trimmingCharacters(in: .whitespaces).lowercased() == confirmationPhrase
    }
}
