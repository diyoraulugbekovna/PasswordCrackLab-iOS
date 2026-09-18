import Foundation

enum CrackPhase: Equatable, CaseIterable {
    case idle
    case personalInfo
    case dictionary
    case bruteForce
    case estimating

    var label: String {
        switch self {
        case .idle:
            return "Starting up"
        case .personalInfo:
            return "Trying guesses based on your email address…"
        case .dictionary:
            return "Trying common leaked passwords + mangling rules…"
        case .bruteForce:
            return "Brute-forcing short combinations (capped at 6 characters)…"
        case .estimating:
            return "Calculating a time-to-crack estimate…"
        }
    }

    /// Short label used in the analyzing screen's step tracker.
    var stepTitle: String {
        switch self {
        case .idle: return "Setup"
        case .personalInfo: return "Email"
        case .dictionary: return "Dictionary"
        case .bruteForce: return "Brute force"
        case .estimating: return "Estimate"
        }
    }

    /// Ordered, visible steps for the step tracker (excludes `.idle`).
    static var trackedSteps: [CrackPhase] { [.personalInfo, .dictionary, .bruteForce, .estimating] }
}
