import SwiftUI
import WinemacCore

struct ContentView: View {
    @Bindable var library: LibraryModel
    @State private var addGame: AddGameModel?

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let bottle = library.selectedBottle {
                BottleDetailView(library: library, bottle: bottle)
                    .id(bottle.name)
            } else {
                ContentUnavailableView {
                    Label("Игр пока нет", systemImage: "gamecontroller")
                } description: {
                    Text("Добавьте папку с Windows-игрой или перетащите её в окно.")
                } actions: {
                    Button("Добавить игру…") { showAddGame() }
                }
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard let folder = urls.first(where: \.hasDirectoryPath) else { return false }
            showAddGame(folder: folder)
            return true
        }
        .task { await library.refresh() }
        .sheet(item: $addGame, onDismiss: { Task { await library.refresh() } }) { model in
            AddGameView(model: model)
        }
        .alert("Ошибка", isPresented: errorIsShown) {
            Button("OK") { library.errorMessage = nil }
        } message: {
            Text(library.errorMessage ?? "")
        }
    }

    private var sidebar: some View {
        List(selection: $library.selectedBottleName) {
            Section("Игры") {
                ForEach(library.bottles) { bottle in
                    Label(bottle.name, systemImage: library.runningBottleName == bottle.name ? "play.circle.fill" : "gamecontroller")
                        .tag(bottle.name)
                }
                Button { showAddGame() } label: {
                    Label("Добавить игру…", systemImage: "plus")
                }
                .buttonStyle(.borderless)
            }
            ServerSection()
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 230)
    }

    private var errorIsShown: Binding<Bool> {
        Binding(get: { library.errorMessage != nil }, set: { if !$0 { library.errorMessage = nil } })
    }

    private func showAddGame(folder: URL? = nil) {
        let model = AddGameModel(cli: library.cli, existingBottleNames: Set(library.bottles.map(\.name)))
        if let folder { model.chooseGameFolder(folder) }
        addGame = model
    }
}

extension AddGameModel: Identifiable {}
