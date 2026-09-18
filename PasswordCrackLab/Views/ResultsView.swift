import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var viewModel: CrackSessionViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                PrivacyNoteView()

                if let outcome = viewModel.outcome {
                    switch outcome {
                    case .exposed(let result):
                        banner(
                            text: "EXPOSED",
                            subtitle: "This password was cracked",
                            systemImage: "exclamationmark.triangle.fill",
                            tint: Theme.exposed
                        )
                        exposedPanel(result)
                    case .safe(let result):
                        banner(
                            text: "SAFE FOR NOW",
                            subtitle: "Not cracked within this lab's limits",
                            systemImage: "checkmark.seal.fill",
                            tint: Theme.safe
                        )
                        safePanel(result)
                    }
                }

                StoragePreviewView(
                    modeLabel: viewModel.hashMode.displayName,
                    saltHex: viewModel.saltHex,
                    storedHash: viewModel.storedHash
                )

                InfoDisclosureView(
                    title: "Why does the hashing method matter so much?",
                    bodyText: "Fast hashes like MD5, SHA-1, and SHA-256 are designed to be computed " +
                        "quickly — great for checksums, bad for password storage, since attackers " +
                        "with GPUs can try billions of guesses per second offline. Slow hashes like " +
                        "bcrypt, argon2, or PBKDF2 with a high iteration count are deliberately " +
                        "expensive, so even offline attackers are limited to a few hundred or thousand " +
                        "guesses per second, buying real time."
                )

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.resetForNewAttempt()
                    }
                } label: {
                    Text("Try another password")
                }
                .buttonStyle(.softSecondary)
                .accessibilityIdentifier("try-again-button")
            }
            .padding()
        }
    }

    private func banner(text: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.calmHeadline().weight(.bold))
                    .foregroundStyle(tint)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .cardStyle(tint: tint)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("result-banner")
    }

    private func exposedPanel(_ result: ExposedResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The password was cracked").font(.calmHeadline())
            VStack(spacing: 0) {
                LabeledRow(label: "Recovered password", value: result.password, monospaced: true)
                Divider()
                LabeledRow(label: "Method", value: result.method)
                Divider()
                LabeledRow(label: "Attempts (measured)", value: formattedAttempts(result.attempts))
                Divider()
                LabeledRow(label: "Time taken (measured)", value: String(format: "%.2fs", result.elapsed))
            }
            ReasonText(result.reason, tint: Theme.exposed)
        }
        .cardStyle()
    }

    private func safePanel(_ result: SafeResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Not cracked within this lab's limits").font(.calmHeadline())
            Text(
                "The dictionary attack and a capped brute-force sweep " +
                "(\(formattedAttempts(result.attempts)) attempts in " +
                "\(String(format: "%.2fs", result.elapsed))) didn't find it. Below is a " +
                "calculated estimate — nothing further was actually attempted."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(result.estimate) { row in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.label).font(.subheadline.weight(.semibold))
                        HStack {
                            Text(row.rateLabel)
                            Spacer()
                            Text(DurationFormatter.format(row.seconds))
                                .fontWeight(.semibold)
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 10)
                    if row.id != result.estimate.last?.id {
                        Divider()
                    }
                }
            }

            ReasonText(result.reason, tint: Theme.safe)
        }
        .cardStyle()
    }

    private func formattedAttempts(_ n: Int) -> String {
        n.formatted(.number.grouping(.automatic))
    }
}

private struct LabeledRow: View {
    let label: String
    var value: String
    var monospaced: Bool = false

    var body: some View {
        HStack(alignment: .top) {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.vertical, 8)
    }
}

private struct ReasonText: View {
    let text: String
    let tint: Color

    init(_ text: String, tint: Color) {
        self.text = text
        self.tint = tint
    }

    var body: some View {
        Text(text)
            .font(.calmBody())
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(tint: tint)
    }
}
