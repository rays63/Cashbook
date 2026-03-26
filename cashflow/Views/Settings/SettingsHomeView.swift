import SwiftUI

struct SettingsHomeView: View {
    @EnvironmentObject private var appearanceSettings: AppearanceSettingsStore
    @AppStorage("cashbook.settings.quickInsights") private var quickInsightsEnabled = true
    @AppStorage("cashbook.settings.confirmDelete") private var confirmDeleteEnabled = true
    @AppStorage("cashbook.settings.calendarHighlights") private var calendarHighlightsEnabled = true

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Settings")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.primaryText)

                        settingSection(title: "Export Settings") {
                            settingsLink(
                                title: "Export Fields",
                                subtitle: "Choose what gets included in PDF and Excel exports",
                                systemImage: "square.and.arrow.up"
                            ) {
                                ExportSettingsView()
                            }
                        }

                        settingSection(title: "Appearance & Region") {
                            appearanceDropdownRow(
                                title: "Theme",
                                subtitle: "Follow system, light, or dark appearance",
                                systemImage: "circle.lefthalf.filled"
                            )

                            toggleRow(
                                title: "Quick Insights",
                                subtitle: "Show the dashboard intelligence card",
                                systemImage: "sparkles",
                                isOn: $quickInsightsEnabled
                            )
                        }

                        settingSection(title: "Data & Preferences") {
                            toggleRow(
                                title: "Delete Confirmation",
                                subtitle: "Ask before removing books or transactions",
                                systemImage: "trash.slash",
                                isOn: $confirmDeleteEnabled
                            )
                            toggleRow(
                                title: "Calendar Highlights",
                                subtitle: "Show markers for active cashflow days",
                                systemImage: "calendar.badge.clock",
                                isOn: $calendarHighlightsEnabled
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func appearanceDropdownRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            settingsIcon(systemImage: systemImage)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Picker("Theme", selection: $appearanceSettings.selectedMode) {
                ForEach(AppAppearanceMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .tint(AppTheme.accent)
        }
        .padding(18)
        .appCardStyle(cornerRadius: 24)
    }

    private func settingSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
            VStack(spacing: 12) {
                content()
            }
        }
    }

    private func settingsLink<Destination: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 14) {
                settingsIcon(systemImage: systemImage)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(18)
            .appCardStyle(cornerRadius: 24)
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(title: String, subtitle: String, systemImage: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            settingsIcon(systemImage: systemImage)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppTheme.accent)
        }
        .padding(18)
        .appCardStyle(cornerRadius: 24)
    }

    private func settingsIcon(systemImage: String) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(AppTheme.accentSoft)
            .frame(width: 42, height: 42)
            .overlay {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }
    }
}
