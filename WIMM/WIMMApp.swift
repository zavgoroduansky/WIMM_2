import SwiftUI
import SwiftData

@main
struct WIMMApp: App {
    var sharedModelContainer: ModelContainer = {
        let localConfiguration = ModelConfiguration(isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(
                for: AccountGroup.self,
                Account.self,
                Category.self,
                Transaction.self,
                configurations: localConfiguration
            )
        } catch {
            fatalError("Could not create local ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
