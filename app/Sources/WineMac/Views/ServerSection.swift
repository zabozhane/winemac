import SwiftUI
import WinemacCore

/// Live state of the local game server linked with `winemac server attach`.
struct ServerSection: View {
    let library: LibraryModel
    private static let pollInterval: Duration = .seconds(3)

    var body: some View {
        Section("Локальный сервер") {
            ForEach(ServerStatus.Component.allCases) { component in
                row(for: component)
            }
            if let server = library.server, server.isAttached {
                controls(for: server)
            } else {
                Text("Не подключён: winemac server attach <игра> <папка сервера>")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            while !Task.isCancelled {
                await library.refreshServer()
                try? await Task.sleep(for: Self.pollInterval)
            }
        }
    }

    private func row(for component: ServerStatus.Component) -> some View {
        let entry = library.server?.entry(for: component) ?? .init(state: .unavailable, detail: "")
        return Label {
            VStack(alignment: .leading, spacing: 1) {
                Text(component.title)
                Text(entry.detail.isEmpty ? entry.state.title : entry.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: entry.state == .unavailable ? "circle" : "circle.fill")
                .foregroundStyle(entry.state.color)
        }
        .help(entry.state.title)
    }

    @ViewBuilder
    private func controls(for server: ServerStatus) -> some View {
        if library.isChangingServer {
            ProgressView().controlSize(.small)
        } else if server.isStopped {
            Button("Запустить сервер", systemImage: "play.fill") {
                Task { await library.startServer() }
            }
            .buttonStyle(.borderless)
        } else {
            Button("Остановить сервер", systemImage: "stop.fill") {
                Task { await library.stopServer() }
            }
            .buttonStyle(.borderless)
            // Stopping the server under a running client would only drop the connection.
            .disabled(library.runningBottleName != nil)
        }
    }
}

private extension ServerStatus.State {
    var title: String {
        switch self {
        case .ready: "работает"
        case .starting: "запускается"
        case .stopped: "остановлен"
        case .failed: "ошибка"
        case .unavailable: "недоступен"
        }
    }

    var color: Color {
        switch self {
        case .ready: .green
        case .starting: .yellow
        case .stopped, .unavailable: .secondary
        case .failed: .red
        }
    }
}
