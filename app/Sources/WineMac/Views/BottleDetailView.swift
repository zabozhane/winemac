import SwiftUI
import AppKit
import WinemacCore

struct BottleDetailView: View {
    let library: LibraryModel
    let bottle: Bottle
    @State private var removal: DeletionModel?

    private var isRunning: Bool { library.runningBottleName == bottle.name }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            HStack(alignment: .top, spacing: 16) {
                DoctorCard(library: library, bottleName: bottle.name)
                LogCard(lines: library.log, logURL: library.cli.logURL(forBottle: bottle.name))
            }
            Spacer(minLength: 0)
        }
        .padding(28)
        .navigationTitle(bottle.name)
        .toolbar {
            Button("Удалить игру…", systemImage: "trash", role: .destructive) {
                removal = DeletionModel(cli: library.cli, arguments: ["remove", bottle.name])
            }
            .disabled(isRunning)
        }
        .sheet(item: $removal, onDismiss: { Task { await library.loadBottles() } }) { model in
            RemoveBottleView(model: model, bottleName: bottle.name)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(bottle.name)
                    .font(.largeTitle.bold())
                Text(bottle.executablePath.map { "drive_c/\($0)" } ?? "Клиент ещё не импортирован")
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                statusLine
                rendererPicker
            }
            Spacer()
            if isRunning {
                Button(role: .destructive) {
                    Task { await library.stop(bottle) }
                } label: {
                    Label("Стоп", systemImage: "stop.fill").frame(minWidth: 90)
                }
                .controlSize(.extraLarge)
                .tint(.red)
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    Task { await library.play(bottle) }
                } label: {
                    Label("Играть", systemImage: "play.fill").frame(minWidth: 110)
                }
                .controlSize(.extraLarge)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(bottle.executablePath == nil || library.runningBottleName != nil)
            }
        }
    }

    private var rendererPicker: some View {
        Picker("Рендер", selection: rendererBinding) {
            ForEach(Renderer.allCases) { renderer in
                Text(renderer.title).tag(Optional(renderer))
            }
        }
        .pickerStyle(.segmented)
        .fixedSize()
        .disabled(isRunning || library.renderers[bottle.name] == nil)
        .help("Применяется при следующем запуске игры")
    }

    private var rendererBinding: Binding<Renderer?> {
        Binding(
            get: { library.renderers[bottle.name] },
            set: { renderer in
                guard let renderer else { return }
                Task { await library.setRenderer(renderer, of: bottle) }
            }
        )
    }

    @ViewBuilder
    private var statusLine: some View {
        if isRunning, let startedAt = library.runStartedAt {
            // Elapsed time ticks without any timer state in the model.
            Label {
                Text("Игра запущена · ") + Text(startedAt, style: .timer)
            } icon: {
                Image(systemName: "circle.fill").foregroundStyle(.green)
            }
            .font(.callout)
        } else if bottle.executablePath != nil {
            Label("Готово к запуску", systemImage: "checkmark.circle")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

struct DoctorCard: View {
    let library: LibraryModel
    let bottleName: String

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                if let report = library.doctor {
                    checks("Система", report.systemSection?.checks ?? [])
                    checks("Бутылка", report.section(forBottle: bottleName)?.checks ?? [])
                } else {
                    ProgressView().frame(maxWidth: .infinity)
                }
                HStack {
                    Button("Проверить (doctor)") { Task { await library.checkDoctor() } }
                        .disabled(library.isChecking)
                    Button("Проверить изоляцию (audit)") { Task { await library.audit() } }
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text("Состояние").font(.headline)
        }
        .frame(width: 340)
    }

    private func checks(_ title: String, _ checks: [DoctorReport.Check]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.bold()).foregroundStyle(.secondary)
            ForEach(checks, id: \.label) { check in
                Label(check.label, systemImage: check.passed ? "checkmark.circle.fill" : "xmark.octagon.fill")
                    .foregroundStyle(check.passed ? Color.primary : Color.red)
                    .symbolRenderingMode(.multicolor)
            }
        }
    }
}

struct LogCard: View {
    let lines: [String]
    let logURL: URL

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                LogView(lines: lines)
                HStack {
                    Spacer()
                    Button("Скопировать") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(lines.joined(separator: "\n"), forType: .string)
                    }
                    Button("Лог Wine в Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([logURL])
                    }
                }
            }
        } label: {
            Text("Журнал").font(.headline)
        }
    }
}
