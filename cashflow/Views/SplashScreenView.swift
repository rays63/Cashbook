import SwiftUI

struct SplashScreenView: View {
    @State private var pulse = false
    @State private var glow = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.52, green: 0.90, blue: 0.30).opacity(glow ? 0.34 : 0.16),
                                Color(red: 0.17, green: 0.72, blue: 0.38).opacity(glow ? 0.22 : 0.08),
                                Color(red: 0.95, green: 0.76, blue: 0.18).opacity(glow ? 0.16 : 0.04),
                                .clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 120
                        )
                    )
                    .frame(width: 228, height: 228)
                    .blur(radius: glow ? 8 : 18)
                    .scaleEffect(glow ? 1.08 : 0.92)

                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 148, height: 148)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .scaleEffect(pulse ? 1.03 : 0.94)
                    .shadow(color: Color(red: 0.44, green: 0.85, blue: 0.28).opacity(glow ? 0.34 : 0.12), radius: glow ? 28 : 10)
                    .shadow(color: Color(red: 0.98, green: 0.78, blue: 0.18).opacity(glow ? 0.16 : 0.04), radius: glow ? 18 : 6)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.82).repeatForever(autoreverses: true)) {
                pulse = true
                glow = true
            }
        }
    }
}
