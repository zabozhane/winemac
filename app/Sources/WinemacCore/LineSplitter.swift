import Foundation

/// Turns arbitrary chunks of process output into complete lines.
/// A pipe delivers data in chunks that can end in the middle of a line, so the tail is kept until the next chunk.
public struct LineSplitter {
    private var pending = Data()

    public init() {}

    public mutating func feed(_ chunk: Data) -> [String] {
        pending.append(chunk)
        var lines: [String] = []
        while let newlineIndex = pending.firstIndex(of: UInt8(ascii: "\n")) {
            lines.append(Self.decode(pending[pending.startIndex..<newlineIndex]))
            pending.removeSubrange(pending.startIndex...newlineIndex)
        }
        return lines
    }

    /// Returns the last line when the output did not end with a newline.
    public mutating func finish() -> String? {
        defer { pending.removeAll() }
        return pending.isEmpty ? nil : Self.decode(pending)
    }

    private static func decode(_ bytes: Data) -> String {
        String(decoding: bytes, as: UTF8.self)
    }
}
