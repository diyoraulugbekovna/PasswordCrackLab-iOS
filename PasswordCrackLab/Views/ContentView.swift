import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CrackSessionViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.pageBackground.ignoresSafeArea()

                Group {
                    switch viewModel.screen {
                    case .login:
                        LoginView().transition(.opacity)
                    case .analyzing:
                        AnalyzingView().transition(.opacity)
                    case .results:
                        ResultsView().transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.35), value: viewModel.screen)
            }
            .navigationTitle("Password Crack Lab")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(Theme.accent)
        .environmentObject(viewModel)
    }
}
