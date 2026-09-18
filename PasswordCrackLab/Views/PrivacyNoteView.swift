import SwiftUI

struct PrivacyNoteView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.shield")
                .foregroundStyle(Theme.accent)
                .font(.footnote.weight(.semibold))
            Text("Runs entirely on this device. Nothing is sent anywhere. Only analyzes the password you just typed.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(tint: Theme.accent)
    }
}
