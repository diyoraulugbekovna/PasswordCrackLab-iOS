import SwiftUI

/// Expandable "what does this mean?" blurb, used on each screen to teach
/// the relevant concept (hashing, salting, dictionary attacks, brute force).
struct InfoDisclosureView: View {
    let title: String
    let bodyText: String
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(bodyText)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 6)
                .fixedSize(horizontal: false, vertical: true)
        } label: {
            Label(title, systemImage: "lightbulb")
                .font(.calmBody().weight(.semibold))
                .foregroundStyle(.primary)
        }
        .tint(Theme.accent)
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
        .cardStyle()
    }
}
