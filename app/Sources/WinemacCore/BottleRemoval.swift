import Foundation

/// The only deleting command the app runs. A full `uninstall` is deliberately CLI-only:
/// in the app it was mistaken for deleting the selected game and wiped every bottle.
public enum BottleRemoval {
    public static func arguments(forBottle name: String) -> [String] {
        ["remove", name]
    }
}
