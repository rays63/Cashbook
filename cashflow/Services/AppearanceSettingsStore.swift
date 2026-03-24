import Combine
import SwiftUI

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Follow System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@MainActor
final class AppearanceSettingsStore: ObservableObject {
    @Published var selectedMode: AppAppearanceMode = .system {
        didSet {
            UserDefaults.standard.set(selectedMode.rawValue, forKey: defaultsKey)
        }
    }

    private let defaultsKey = "cashbook.appearance.mode"

    init() {
        if let rawValue = UserDefaults.standard.string(forKey: defaultsKey),
           let mode = AppAppearanceMode(rawValue: rawValue) {
            selectedMode = mode
        }
    }
}
