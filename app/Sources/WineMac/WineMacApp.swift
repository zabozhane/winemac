import SwiftUI
import WinemacCore

@main
struct WineMacApp: App {
    var body: some Scene {
        Window("winemac", id: "main") {
            RootView()
        }
        .defaultSize(width: 1080, height: 700)
    }
}

struct RootView: View {
    @State private var library = Self.makeLibrary()

    var body: some View {
        switch library {
        case .success(let library):
            ContentView(library: library)
        case .failure(let error):
            ContentUnavailableView("winemac не найден", systemImage: "exclamationmark.triangle",
                                   description: Text(error.localizedDescription))
        }
    }

    /// The app bundle is built into the winemac folder, next to bin/winemac.
    @MainActor
    private static func makeLibrary() -> Result<LibraryModel, Error> {
        let root = Bundle.main.bundleURL.deletingLastPathComponent()
        return Result { LibraryModel(cli: try WinemacCLI(rootURL: root)) }
    }
}
