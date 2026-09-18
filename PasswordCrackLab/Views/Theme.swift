import SwiftUI

/// A small, calm design system shared across every screen: one accent, one
/// pair of semantic colors for exposed/safe, and consistent spacing/radii so
/// the app reads as one considered surface rather than a stack of defaults.
enum Theme {
    /// A calm indigo — mid-brightness so it reads clearly in both light and
    /// dark mode without needing separate asset-catalog variants.
    static let accent = Color(red: 0.35, green: 0.40, blue: 0.82)

    static let safe = Color(red: 0.16, green: 0.55, blue: 0.42)
    static let exposed = Color(red: 0.78, green: 0.36, blue: 0.24)

    static let cardCornerRadius: CGFloat = 18
    static let controlCornerRadius: CGFloat = 12
    static let sectionSpacing: CGFloat = 22

    static var cardBackground: Color {
        Color(.secondarySystemGroupedBackground)
    }

    static var pageBackground: Color {
        Color(.systemGroupedBackground)
    }
}

/// Rounded, slightly softer type — reinforces the "learning tool, not a
/// hacking tool" tone from the copy itself.
extension Font {
    static func calmTitle() -> Font { .system(.title2, design: .rounded).weight(.bold) }
    static func calmHeadline() -> Font { .system(.headline, design: .rounded) }
    static func calmBody() -> Font { .system(.subheadline, design: .rounded) }
    static func calmCounter() -> Font { .system(.title, design: .rounded).weight(.semibold) }
}

/// Standard card container: consistent padding, corner radius, and a soft
/// shadow instead of hard borders — the "smooth and calm" surface language
/// used everywhere on every screen.
struct CardBackground: ViewModifier {
    var tint: Color?

    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                    .fill(tint?.opacity(0.10) ?? Theme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                    .strokeBorder(tint?.opacity(0.25) ?? Color.clear, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(tint: Color? = nil) -> some View {
        modifier(CardBackground(tint: tint))
    }
}

/// A gentle press animation instead of the system default flash — used for
/// both primary and secondary buttons so interactions feel soft.
struct SoftButtonStyle: ButtonStyle {
    var kind: Kind

    enum Kind { case primary, secondary }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.calmHeadline().weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: Theme.controlCornerRadius, style: .continuous)
                    .fill(kind == .primary ? Theme.accent : Theme.cardBackground)
            )
            .foregroundStyle(kind == .primary ? Color.white : Theme.accent)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SoftButtonStyle {
    static var softPrimary: SoftButtonStyle { SoftButtonStyle(kind: .primary) }
    static var softSecondary: SoftButtonStyle { SoftButtonStyle(kind: .secondary) }
}
