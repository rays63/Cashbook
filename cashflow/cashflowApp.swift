import CoreData
import SwiftUI

@main
struct CashBookProApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var exportSettings = ExportSettingsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(exportSettings)
        }
    }
}
