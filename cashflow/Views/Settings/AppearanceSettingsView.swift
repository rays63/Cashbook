import SwiftUI

struct AppearanceSettingsView: View {
    @EnvironmentObject private var appearanceSettings: AppearanceSettingsStore

    var body: some View {
        ZStack {
            AppBackgroundView()

            List {
                Section {
                    ForEach(AppAppearanceMode.allCases) { mode in
                        Button {
                            appearanceSettings.selectedMode = mode
                        } label: {
                            HStack {
                                Text(mode.title)
                                    .foregroundStyle(AppTheme.primaryText)
                                Spacer()
                                if appearanceSettings.selectedMode == mode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.accent)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Choose whether the app should follow the system theme or stay locked to light or dark mode.")
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle("Appearance")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
