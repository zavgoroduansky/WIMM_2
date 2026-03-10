import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var dependencies = AppDependencies()

    var body: some View {
        Group {
            if dependencies.isConfigured {
                TabView {
                    AccountsScene(dependencies: dependencies)
                        .tabItem {
                            Label("Accounts", systemImage: "wallet.pass")
                        }

                    CategoriesScene(dependencies: dependencies)
                        .tabItem {
                            Label("Categories", systemImage: "list.bullet")
                        }

                    HistoryScene(dependencies: dependencies)
                        .tabItem {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }

                    ReportsScene(dependencies: dependencies)
                        .tabItem {
                            Label("Reports", systemImage: "chart.bar")
                        }

                    SettingsScene(dependencies: dependencies)
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            dependencies.configure(modelContext: modelContext)
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
