import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultCurrency") private var defaultCurrencyRaw = CurrencyCode.eur.rawValue
    @ObservedObject var viewModel: SettingsViewModel
    let makeManageAccountsView: () -> AnyView
    let makeManageCategoriesView: () -> AnyView

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
                        makeManageAccountsView()
                    }
                    NavigationLink("Categories") {
                        makeManageCategoriesView()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    let viewModel = SettingsViewModel()
    return SettingsView(
        viewModel: viewModel,
        makeManageAccountsView: { AnyView(EmptyView()) },
        makeManageCategoriesView: { AnyView(EmptyView()) }
    )
}
