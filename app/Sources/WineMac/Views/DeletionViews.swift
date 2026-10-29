import SwiftUI
import AppKit
import WinemacCore

/// Shared confirmation sheet for commands that list what they delete and then ask y/N.
struct DeletionSheet<Listing: View>: View {
    let model: DeletionModel
    let title: String
    let confirmTitle: String
    let deletedTitle: String
    let onDeleted: () -> Void
    @ViewBuilder let listing: () -> Listing
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: "exclamationmark.triangle.fill")
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
                Text("Отменить удаление нельзя.").foregroundStyle(.secondary)
                listing()
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
                Button(confirmTitle, role: .destructive) { Task { await model.confirm() } }
                    .tint(.red)
                    .buttonStyle(.borderedProminent)
            case .deleted:
                Button(deletedTitle, action: onDeleted)
                    .keyboardShortcut(.defaultAction)
            case .failed, .cancelled:
                Button("Закрыть") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
    }
}

struct UninstallView: View {
    let model: DeletionModel

    var body: some View {
        DeletionSheet(model: model, title: "Удалить всё, что создал winemac?", confirmTitle: "Удалить всё",
                      // The app bundle itself was inside the deleted folder.
                      deletedTitle: "Закрыть winemac", onDeleted: { NSApp.terminate(nil) }) {
            let plan = model.plan
            Text("Игры будут остановлены.").foregroundStyle(.secondary)
            SizedPaths(items: plan.items)
            if !plan.homebrewFormulae.isEmpty {
                Text("Формулы Homebrew, которые поставил winemac: \(plan.homebrewFormulae.joined(separator: ", "))")
            }
            Text("Не трогаем: Rosetta 2 и сам Homebrew. Папка, из которой импортировали игру, остаётся на месте.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct RemoveBottleView: View {
    let model: DeletionModel
    let bottleName: String
    @Environment(\.dismiss) private var dismiss

    private static let gamePrefix = "game inside it:"
    private static let logPrefix = "log:"

    var body: some View {
        DeletionSheet(model: model, title: "Удалить игру \(bottleName)?", confirmTitle: "Удалить",
                      deletedTitle: "Готово", onDeleted: { dismiss() }) {
            SizedPaths(items: model.plan.items)
            ForEach(details, id: \.self) { Text($0).font(.callout.monospaced()) }
            Text("Не трогаем: Wine, другие бутылки и кэш загрузок winetricks. Папка, из которой импортировали игру, остаётся на месте.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
    let items: [UninstallPlan.Item]

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
