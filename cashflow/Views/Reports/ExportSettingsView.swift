import SwiftUI

struct ExportSettingsView: View {
    @EnvironmentObject private var exportSettings: ExportSettingsStore

    var body: some View {
        ZStack {
            AppBackgroundView()

            List {
                Section("Choose fields to export") {
                    ForEach(ExportField.allCases) { field in
                        Toggle(isOn: Binding(
                            get: { exportSettings.selectedFields.contains(field) },
                            set: { _ in exportSettings.toggle(field) }
                        )) {
                            Text(field.rawValue)
                                .foregroundStyle(AppTheme.primaryText)
                        }
                    }
                }
                .listRowBackground(AppTheme.listRowFill)

                Section {
                    Text("At least one field stays selected so exported files always remain readable.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .listRowBackground(AppTheme.listRowFill)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Export Settings")
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
