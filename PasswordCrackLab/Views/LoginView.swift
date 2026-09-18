import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var viewModel: CrackSessionViewModel
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sectionSpacing) {
                PrivacyNoteView()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Demo Login")
                        .font(.calmTitle())
                    Text(
                        "This is a local educational demo, not a real login. No account is created " +
                        "and nothing is authenticated. We'll also try guessing the password from the " +
                        "email below, since real attackers often do the same."
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 16) {
                    field(label: "Email") {
                        TextField("you@example.com", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(nil)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                            .accessibilityIdentifier("email-field")
                    }

                    field(label: "Password") {
                        SecureField("Type any password to analyze", text: $viewModel.password)
                            .textContentType(nil)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { submit() }
                            .accessibilityIdentifier("password-field")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("How should this password be \"stored\"?")
                            .font(.subheadline.weight(.semibold))
                        Picker("Storage mode", selection: $viewModel.hashMode) {
                            ForEach(HashMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.controlCornerRadius, style: .continuous)
                                .fill(Theme.cardBackground)
                        )
                        .accessibilityIdentifier("hash-mode-picker")
                    }

                    Button(action: submit) {
                        Text("Analyze this password")
                    }
                    .buttonStyle(.softPrimary)
                    .disabled(viewModel.password.isEmpty)
                    .opacity(viewModel.password.isEmpty ? 0.5 : 1)
                    .accessibilityIdentifier("submit-button")
                }
                .cardStyle()

                InfoDisclosureView(
                    title: "What does \"hashing\" mean?",
                    bodyText: "A hash function turns a password into a fixed-length scramble of " +
                        "characters that (in theory) can't be reversed back into the original password. " +
                        "Sites are supposed to store this scramble instead of your actual password, so " +
                        "that if their database ever leaks, attackers don't get plaintext passwords " +
                        "directly — they have to guess."
                )

                InfoDisclosureView(
                    title: "What is a \"salt\"?",
                    bodyText: "A salt is a random value mixed into the password before hashing. It's not " +
                        "secret — it's usually stored right next to the hash. Its job is to make every " +
                        "hash unique, even for two users with the same password, so attackers can't " +
                        "pre-compute one giant lookup table that works against every account at once."
                )

                InfoDisclosureView(
                    title: "Why does my email matter here?",
                    bodyText: "People frequently reuse their email address, username, or name as part of " +
                        "their password. Real attackers know this, so before trying a generic word list " +
                        "they often try guesses built from exactly what you typed above. This lab does " +
                        "the same, using only the email you entered in this one session."
                )
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private func field<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.subheadline.weight(.semibold))
            content()
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: Theme.controlCornerRadius, style: .continuous)
                        .fill(Theme.pageBackground)
                )
        }
    }

    private func submit() {
        focusedField = nil
        viewModel.submit()
    }
}
