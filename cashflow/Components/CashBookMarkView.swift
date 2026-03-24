import SwiftUI

struct CashBookMarkView: View {
    var size: CGFloat = 132
    var showShadow: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.46, green: 0.82, blue: 0.22),
                            Color(red: 0.17, green: 0.58, blue: 0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: size * 0.012)

            ZStack {
                Image(systemName: "book.pages.fill")
                    .font(.system(size: size * 0.50, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: Color.black.opacity(0.10), radius: size * 0.04, x: 0, y: size * 0.03)

                Text("$")
                    .font(.system(size: size * 0.17, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.18, green: 0.60, blue: 0.25))
                    .offset(x: size * 0.13, y: -size * 0.02)

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.86, blue: 0.35),
                                    Color(red: 0.97, green: 0.71, blue: 0.16)
                                ],
                                center: .center,
                                startRadius: 4,
                                endRadius: size * 0.16
                            )
                        )

                    Circle()
                        .stroke(Color(red: 0.98, green: 0.92, blue: 0.56), lineWidth: size * 0.022)

                    Text("$")
                        .font(.system(size: size * 0.15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.95))
                }
                .frame(width: size * 0.24, height: size * 0.24)
                .shadow(color: Color.black.opacity(0.18), radius: size * 0.05, x: 0, y: size * 0.03)
                .offset(x: size * 0.24, y: size * 0.20)
            }
            .padding(size * 0.12)
        }
        .frame(width: size, height: size)
        .shadow(color: showShadow ? Color.black.opacity(0.12) : .clear, radius: size * 0.08, x: 0, y: size * 0.04)
    }
}
