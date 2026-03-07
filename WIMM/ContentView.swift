import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            AccountsView()
                .tabItem {
                    Label("Accounts", systemImage: "wallet.pass")
                }

            CategoriesView()
                .tabItem {
                    Label("Categories", systemImage: "list.bullet")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "chart.bar")
                }

            SettingsView()
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
