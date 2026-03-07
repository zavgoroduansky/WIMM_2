import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultCurrency") private var defaultCurrencyRaw = CurrencyCode.eur.rawValue
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    Picker("Default currency", selection: $defaultCurrencyRaw) {
                        ForEach(viewModel.allCurrencies) { currency in
                            Text("\(currency.displayName) (\(currency.symbol))")
                                .tag(currency.rawValue)
                        }
                    }
                }

                Section("Data") {
                    NavigationLink("Accounts") {
                        ManageAccountsView()
                    }
                    NavigationLink("Categories") {
                        ManageCategoriesView()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
