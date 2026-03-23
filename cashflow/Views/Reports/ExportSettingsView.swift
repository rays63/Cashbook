import SwiftUI

struct ExportSettingsView: View {
    @EnvironmentObject private var exportSettings: ExportSettingsStore

    var body: some View {
        List {
            Section("Choose fields to export") {
                ForEach(ExportField.allCases) { field in
                    Toggle(isOn: Binding(
                        get: { exportSettings.selectedFields.contains(field) },
                        set: { _ in exportSettings.toggle(field) }
                    )) {
                        Text(field.rawValue)
                    }
                }
            }

            Section {
                Text("At least one field stays selected so exported files always remain readable.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Export Settings")
    }
}
