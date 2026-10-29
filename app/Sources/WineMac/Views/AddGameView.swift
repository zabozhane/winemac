import SwiftUI
import UniformTypeIdentifiers
import WinemacCore

struct AddGameView: View {
    @Bindable var model: AddGameModel
    @Environment(\.dismiss) private var dismiss
    @State private var isPickingFolder = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Добавить игру").font(.title2.bold())
            form
            Text("Папка копируется внутрь бутылки, оригинал не меняется.")
                .font(.caption)
                .foregroundStyle(.secondary)
            if !model.plannedSteps.isEmpty { progress }
            buttons
        }
        .padding(24)
        .frame(width: 560)
        .fileImporter(isPresented: $isPickingFolder, allowedContentTypes: [.folder]) { result in
            if case .success(let folder) = result { model.chooseGameFolder(folder) }
        }
    }

    private var form: some View {
        Form {
            TextField("Название бутылки", text: $model.bottleName)
            LabeledContent("Папка клиента") {
                HStack {
                    Text(model.gameFolder?.path ?? "не выбрана")
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(model.gameFolder == nil ? .secondary : .primary)
                    Button("Выбрать…") { isPickingFolder = true }
                }
            }
            if model.gameFolder != nil {
                Picker("Что запускать", selection: $model.selectedExecutable) {
                    ForEach(model.executables, id: \.self) { path in
                        Text(path).font(.body.monospaced()).tag(Optional(path))
                    }
                }
                .pickerStyle(.radioGroup)
            }
            LabeledContent("Зависимости") {
                HStack {
                    ForEach(AddGameModel.defaultDependencies, id: \.self) { verb in
                        Toggle(verb, isOn: dependencyBinding(verb))
                    }
                }
            }
        }
        .disabled(model.isInstalling || model.isFinished)
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(model.plannedSteps) { step in
                HStack {
                    stepIcon(model.state(of: step))
                    Text(step.title)
                }
            }
            LogView(lines: model.log).frame(height: 140)
        }
    }

    @ViewBuilder
    private func stepIcon(_ state: AddGameModel.StepState) -> some View {
        switch state {
        case .pending: Image(systemName: "circle").foregroundStyle(.secondary)
        case .running: ProgressView().controlSize(.small)
        case .done: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed: Image(systemName: "xmark.octagon.fill").foregroundStyle(.red)
        }
    }

    private var buttons: some View {
        HStack {
            Spacer()
            if model.isFinished {
                Button("Готово") { dismiss() }.keyboardShortcut(.defaultAction)
            } else {
                Button("Отмена") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .disabled(model.isInstalling)
                Button(model.isInstalling ? "Устанавливается…" : "Добавить") {
                    Task { await model.install() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!model.canInstall)
            }
        }
    }

    private func dependencyBinding(_ verb: String) -> Binding<Bool> {
        Binding(
            get: { model.selectedDependencies.contains(verb) },
            set: { isOn in
                if isOn { model.selectedDependencies.insert(verb) } else { model.selectedDependencies.remove(verb) }
            }
        )
    }
}
