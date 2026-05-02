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
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
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
