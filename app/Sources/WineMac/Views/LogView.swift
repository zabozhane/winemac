import SwiftUI

/// Command output that follows the newest line.
struct LogView: View {
    let lines: [String]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        Text(line).id(index)
                    }
                }
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
            }
            .frame(minHeight: 160)
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .onChange(of: lines.count) { _, count in
                proxy.scrollTo(count - 1, anchor: .bottom)
            }
        }
    }
}
