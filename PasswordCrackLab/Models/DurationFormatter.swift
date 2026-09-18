import Foundation

enum DurationFormatter {
    private static let year: Double = 365.25 * 24 * 3600

    static func format(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "effectively never" }
        if seconds < 1 { return "under 1 second" }
        if seconds < 60 { return String(format: "%.1f seconds", seconds) }
        if seconds < 3600 { return String(format: "%.1f minutes", seconds / 60) }
        if seconds < 86400 { return String(format: "%.1f hours", seconds / 3600) }
        if seconds < year { return String(format: "%.1f days", seconds / 86400) }

        let years = seconds / year
        if years < 1000 { return String(format: "%.1f years", years) }
        if years < 1e6 { return String(format: "%.1f thousand years", years / 1e3) }
        if years < 1e9 { return String(format: "%.1f million years", years / 1e6) }
        if years < 1e12 { return String(format: "%.1f billion years", years / 1e9) }
        if years < 1e15 { return String(format: "%.1f trillion years", years / 1e12) }
        return String(format: "%.2e years", years)
    }
}
