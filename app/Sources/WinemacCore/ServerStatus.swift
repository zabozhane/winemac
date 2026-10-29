import Foundation

/// Result of `winemac server status`: one "component<TAB>state<TAB>detail" line per component.
public struct ServerStatus: Equatable {
    public enum State: String {
        case ready, starting, stopped, failed, unavailable
    }

    public enum Component: String, CaseIterable, Identifiable {
        case docker, mariadb, login, game, ollama

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .docker: "Docker"
            case .mariadb: "MariaDB"
            case .login: "Login-сервер aCis"
            case .game: "Game-сервер aCis"
            case .ollama: "Ollama"
            }
        }
    }

    public struct Entry: Equatable {
        public let state: State
        public let detail: String
    }

    public var entries: [Component: Entry]

    public func entry(for component: Component) -> Entry {
        entries[component] ?? Entry(state: .unavailable, detail: "")
    }

    /// False until `winemac server attach` has linked a server folder.
    public var isAttached: Bool {
        entries.values.contains { $0.state != .unavailable }
    }

    /// Ollama is optional, so the server counts as running once the components the game needs are.
    private static let required: [Component] = [.mariadb, .login, .game]

    public var isReady: Bool {
        Self.required.allSatisfy { entry(for: $0).state == .ready }
    }

    public var isStopped: Bool {
        Self.required.allSatisfy { [.stopped, .unavailable].contains(entry(for: $0).state) }
    }

    public static func parse(_ lines: [String]) -> ServerStatus {
        var entries: [Component: Entry] = [:]
        for line in lines {
            let fields = line.split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false).map(String.init)
            guard fields.count >= 2,
                  let component = Component(rawValue: fields[0]),
                  let state = State(rawValue: fields[1]) else { continue }
            entries[component] = Entry(state: state, detail: fields.count > 2 ? fields[2] : "")
        }
        return ServerStatus(entries: entries)
    }
}
