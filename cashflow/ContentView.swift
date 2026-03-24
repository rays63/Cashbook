import SwiftUI

struct ContentView: View {
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            BooksHomeView()

            if isShowingSplash {
                SplashScreenView()
                    .transition(.opacity.combined(with: .scale(scale: 1.03)))
                    .zIndex(1)
            }
        }
        .task {
            guard isShowingSplash else { return }
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeInOut(duration: 0.45)) {
                isShowingSplash = false
            }
        }
    }
}
