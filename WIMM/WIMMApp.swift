import SwiftUI
import SwiftData

@main
struct WIMMApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: WIMMSchemaV2.self)
        let localConfiguration = ModelConfiguration(isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: WIMMMigrationPlan.self,
                configurations: [localConfiguration]
            )
        } catch {
            fatalError("Could not create local ModelContainer with migration plan: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
