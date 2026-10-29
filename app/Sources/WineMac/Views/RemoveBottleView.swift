import SwiftUI
import WinemacCore

struct RemoveBottleView: View {
    let model: RemoveBottleModel
    @Environment(\.dismiss) private var dismiss

    private static let gamePrefix = "game inside it:"
    private static let logPrefix = "log:"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Удалить игру \(model.bottleName)?", systemImage: "exclamationmark.triangle.fill")
                .font(.title2.bold())
                .symbolRenderingMode(.multicolor)
            content
            buttons
        }
        .padding(24)
        .frame(width: 600)
        // The CLI waits for an answer on stdin, so the sheet closes only through the buttons.
        .interactiveDismissDisabled()
        .task { await model.loadListing() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .loading:
            ProgressView("Считаю, что будет удалено…")
        case .confirming:
            VStack(alignment: .leading, spacing: 10) {
                Text("Бутылка и лог переместятся в Корзину, оттуда их можно вернуть.").foregroundStyle(.secondary)
                SizedPaths(items: model.parsedListing.items)
                ForEach(details, id: \.self) { Text($0).font(.callout.monospaced()) }
                Text("Не трогаем: Wine, другие игры и кэш загрузок winetricks. Папка, из которой импортировали игру, остаётся на месте.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .deleting, .deleted, .failed, .cancelled:
            LogView(lines: model.log).frame(height: 220)
        }
    }

    @ViewBuilder
    private var buttons: some View {
        HStack {
            Spacer()
            switch model.phase {
            case .loading, .deleting:
                EmptyView()
            case .confirming:
                Button("Отмена") { Task { await model.cancel(); dismiss() } }
                    .keyboardShortcut(.cancelAction)
                Button("Удалить", role: .destructive) { Task { await model.confirm() } }
                    .tint(.red)
                    .buttonStyle(.borderedProminent)
            case .deleted, .failed, .cancelled:
                Button("Закрыть") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    /// The game and log rows of `winemac remove`, translated.
    private var details: [String] {
        model.listing.compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix(Self.gamePrefix) { return "Игра: " + trimmed.dropFirst(Self.gamePrefix.count).trimmingCharacters(in: .whitespaces) }
            if trimmed.hasPrefix(Self.logPrefix) { return "Лог: " + trimmed.dropFirst(Self.logPrefix.count).trimmingCharacters(in: .whitespaces) }
            return nil
        }
    }
}

private struct SizedPaths: View {
    let items: [DeletionListing.Item]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
            ForEach(items, id: \.path) { item in
                GridRow {
                    Text(item.path).font(.body.monospaced())
                    Text(item.size).foregroundStyle(.secondary).gridColumnAlignment(.trailing)
                }
            }
        }
    }
}
