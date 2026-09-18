import Foundation

struct EstimateRow: Identifiable {
    let id = UUID()
    let label: String
    let rateLabel: String
    let seconds: Double
}

struct ExposedResult {
    let password: String
    let method: String
    let attempts: Int
    let elapsed: TimeInterval
    let reason: String
}

struct SafeResult {
    let attempts: Int
    let elapsed: TimeInterval
    let passwordLength: Int
    let charsetSize: Int
    let keyspace: Double
    let estimate: [EstimateRow]
    let reason: String
}

enum CrackOutcome {
    case exposed(ExposedResult)
    case safe(SafeResult)
}

/// Raw result handed back by the cracking engine, before the view model
/// attaches a plain-language reason and turns it into a `CrackOutcome`.
enum EngineOutcome {
    case found(password: String, method: String, attempts: Int, elapsed: TimeInterval)
    case notFound(
        attempts: Int,
        elapsed: TimeInterval,
        passwordLength: Int,
        charsetSize: Int,
        keyspace: Double,
        estimate: [EstimateRow]
    )
}
