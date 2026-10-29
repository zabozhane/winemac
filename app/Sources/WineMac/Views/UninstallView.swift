import SwiftUI
import AppKit
import WinemacCore

struct UninstallView: View {
    let model: UninstallModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Удалить всё, что создал winemac?", systemImage: "exclamationmark.triangle.fill")
                .font(.title2.bold())
                .symbolRenderingMode(.multicolor)
            content
            buttons
        }
        .padding(24)
        .frame(width: 600)
        // The CLI waits for an answer on stdin, so the sheet closes only through the buttons.
        .interactiveDismissDisabled()
        .task { await model.loadPlan() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .loading:
            ProgressView("Считаю, что будет удалено…")
        case .confirming:
            plan
        case .deleting, .deleted, .failed, .cancelled:
            LogView(lines: model.log).frame(height: 220)
        }
    }

    private var plan: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Игра и сервер будут остановлены. Отменить удаление нельзя.")
                .foregroundStyle(.secondary)
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                ForEach(model.plan.items, id: \.path) { item in
                    GridRow {
                        Text(item.path).font(.body.monospaced())
                        Text(item.size).foregroundStyle(.secondary).gridColumnAlignment(.trailing)
                    }
                }
            }
            if !model.plan.homebrewFormulae.isEmpty {
                Text("Формулы Homebrew, которые поставил winemac: \(model.plan.homebrewFormulae.joined(separator: ", "))")
            }
            Text("Не трогаем: Rosetta 2 и сам Homebrew. Папка, из которой импортировали игру, остаётся на месте.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
                Button("Удалить всё", role: .destructive) { Task { await model.confirm() } }
                    .tint(.red)
                    .buttonStyle(.borderedProminent)
            case .deleted:
                // The app bundle itself was inside the deleted folder.
                Button("Закрыть winemac") { NSApp.terminate(nil) }
                    .keyboardShortcut(.defaultAction)
            case .failed, .cancelled:
                Button("Закрыть") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
    }
}
