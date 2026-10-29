import SwiftUI

/// Placeholder for the launch hooks of stage 5; the CLI has no server commands yet.
struct ServerSection: View {
    private static let services = ["MariaDB", "Login-сервер aCis", "Game-сервер aCis", "Ollama"]

    var body: some View {
        Section("Локальный сервер") {
            ForEach(Self.services, id: \.self) { service in
                Label(service, systemImage: "circle")
                    .foregroundStyle(.secondary)
            }
            Text("Появится вместе с хуками запуска")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
