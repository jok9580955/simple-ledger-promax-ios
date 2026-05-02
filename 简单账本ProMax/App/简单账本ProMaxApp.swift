import SwiftData
import SwiftUI

@main
struct SimpleLedgerProMaxApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LedgerTransaction.self,
            LedgerCategory.self,
            LedgerAccount.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: ScreenshotMode.isEnabled)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            if ScreenshotMode.isEnabled {
                let context = ModelContext(container)
                SeedData.ensureScreenshotData(in: context)
            }
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
