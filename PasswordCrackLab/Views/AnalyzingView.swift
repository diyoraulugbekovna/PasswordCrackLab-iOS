import SwiftUI

struct AnalyzingView: View {
    @EnvironmentObject private var viewModel: CrackSessionViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.sectionSpacing) {
                PrivacyNoteView()

                VStack(spacing: 14) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.large)
                        .tint(Theme.accent)

                    Text("Analyzing your password…")
                        .font(.calmTitle())

                    Text(viewModel.phase.label)
                        .font(.calmBody())
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut, value: viewModel.phase)
                        .transition(.opacity)
                        .id(viewModel.phase)
                }
                .cardStyle()

                PhaseStepper(currentPhase: viewModel.phase)
                    .cardStyle()

                HStack(spacing: 32) {
                    counter(value: "\(viewModel.attempts)", label: "ATTEMPTS TRIED")
                    counter(value: String(format: "%.1fs", viewModel.elapsed), label: "ELAPSED")
                }
                .cardStyle()

                StoragePreviewView(
                    modeLabel: viewModel.hashMode.displayName,
                    saltHex: viewModel.saltHex,
                    storedHash: viewModel.storedHash
                )

                InfoDisclosureView(
                    title: "What's a dictionary attack?",
                    bodyText: "Instead of guessing randomly, attackers first try passwords known to be " +
                        "common — leaked from real breaches, or generated with simple tweaks like " +
                        "capitalizing the first letter or adding \"123\" or the current year. Most " +
                        "real-world passwords fall in the first few thousand guesses this way."
                )

                InfoDisclosureView(
                    title: "What's brute force?",
                    bodyText: "If the dictionary doesn't work, an attacker can try every possible " +
                        "combination of characters, starting from short ones. This gets astronomically " +
                        "slower as length and character variety increase — that growth is the entire " +
                        "reason long, varied passwords matter."
                )
            }
            .padding()
        }
    }

    private func counter(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.calmCounter())
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.2), value: value)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A calm, horizontal tracker showing which stage the engine is in. Since
/// the underlying algorithm doesn't produce a single linear percentage,
/// this shows discrete stages instead of a fake determinate progress bar.
private struct PhaseStepper: View {
    let currentPhase: CrackPhase

    private var currentIndex: Int {
        CrackPhase.trackedSteps.firstIndex(of: currentPhase) ?? -1
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(CrackPhase.trackedSteps.enumerated()), id: \.offset) { index, step in
                VStack(spacing: 6) {
                    Circle()
                        .fill(color(for: index))
                        .frame(width: 10, height: 10)
                    Text(step.stepTitle)
                        .font(.caption2.weight(index == currentIndex ? .semibold : .regular))
                        .foregroundStyle(index <= currentIndex ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)

                if index < CrackPhase.trackedSteps.count - 1 {
                    Rectangle()
                        .fill(index < currentIndex ? Theme.accent : Theme.pageBackground)
                        .frame(height: 2)
                        .offset(y: -8)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentIndex)
    }

    private func color(for index: Int) -> Color {
        if index < currentIndex { return Theme.accent }
        if index == currentIndex { return Theme.accent }
        return Theme.pageBackground
    }
}
