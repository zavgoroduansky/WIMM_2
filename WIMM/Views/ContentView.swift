import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dependencies = AppDependencies()

    var body: some View {
        TabView {
            AccountsScene(modelContext: modelContext, dependencies: dependencies)
                .tabItem {
                    Label("Accounts", systemImage: "wallet.pass")
                }

            CategoriesScene(modelContext: modelContext, dependencies: dependencies)
                .tabItem {
                    Label("Categories", systemImage: "list.bullet")
                }

            HistoryScene(modelContext: modelContext, dependencies: dependencies)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            ReportsScene(modelContext: modelContext, dependencies: dependencies)
                .tabItem {
                    Label("Reports", systemImage: "chart.bar")
                }

            SettingsScene(modelContext: modelContext, dependencies: dependencies)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [AccountGroup.self, Account.self, Category.self, Transaction.self],
            inMemory: true
        )
}
