import SwiftUI
import UIKit

enum AppTheme {
    static let backgroundTop = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.10, blue: 0.10, alpha: 1)
            : UIColor(red: 0.97, green: 0.98, blue: 0.96, alpha: 1)
    })
    static let backgroundBottom = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.05, green: 0.14, blue: 0.12, alpha: 1)
            : UIColor(red: 0.92, green: 0.95, blue: 0.93, alpha: 1)
    })
    static let cardFill = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.white.withAlphaComponent(0.84)
    })
    static let cardStroke = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.white.withAlphaComponent(0.75)
    })
    static let primaryText = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.94, green: 0.96, blue: 0.95, alpha: 1)
            : UIColor(red: 0.09, green: 0.14, blue: 0.12, alpha: 1)
    })
    static let secondaryText = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.63, green: 0.72, blue: 0.69, alpha: 1)
            : UIColor(red: 0.35, green: 0.42, blue: 0.39, alpha: 1)
    })
    static let success = Color(red: 0.10, green: 0.55, blue: 0.37)
    static let danger = Color(red: 0.78, green: 0.28, blue: 0.22)
    static let accent = Color(red: 0.14, green: 0.45, blue: 0.39)
    static let accentSoft = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.25, blue: 0.22, alpha: 1)
            : UIColor(red: 0.83, green: 0.92, blue: 0.88, alpha: 1)
    })
    static let shadow = Color.black.opacity(0.10)
    static let listRowFill = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.04)
            : UIColor.white.withAlphaComponent(0.6)
    })
}

struct AppBackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(AppTheme.accent.opacity(0.08))
                .frame(width: 220, height: 220)
                .offset(x: 70, y: -80)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(AppTheme.success.opacity(0.08))
                .frame(width: 180, height: 180)
                .offset(x: -50, y: 70)
        }
        .ignoresSafeArea()
    }
}

extension View {
    func appCardStyle(cornerRadius: CGFloat = 24) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
            .shadow(color: AppTheme.shadow, radius: 18, x: 0, y: 10)
    }
}
