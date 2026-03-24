import CoreData
import SwiftUI

@main
struct CashBookProApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var exportSettings = ExportSettingsStore()
    @StateObject private var appearanceSettings = AppearanceSettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(exportSettings)
                .environmentObject(appearanceSettings)
                .preferredColorScheme(appearanceSettings.selectedMode.preferredColorScheme)
                .tint(AppTheme.accent)
        }
    }
}
