import SwiftUI

/// Shows "what would actually be stored" for the entered password: the
/// chosen hashing mode, the (non-secret) salt, and the resulting value.
struct StoragePreviewView: View {
    let modeLabel: String
    let saltHex: String
    let storedHash: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("What would actually be stored", systemImage: "externaldrive")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            row(label: "Mode", value: modeLabel)
            row(label: "Salt", value: saltHex, monospaced: true)
            row(label: "Stored value", value: storedHash, monospaced: true)
        }
        .cardStyle()
    }

    private func row(label: String, value: String, monospaced: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(monospaced ? .system(.footnote, design: .monospaced) : .footnote)
                .textSelection(.enabled)
        }
    }
}
