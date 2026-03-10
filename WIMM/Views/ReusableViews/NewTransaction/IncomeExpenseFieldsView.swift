import SwiftUI

struct IncomeExpenseFieldsView: View {
    @ObservedObject var viewModel: NewTransactionViewModel

    var body: some View {
        TextField("Amount", text: $viewModel.amount)
            .keyboardType(.decimalPad)

        Picker("Account", selection: $viewModel.accountID) {
            ForEach(viewModel.orderedAccounts, id: \.id) { account in
                Text(viewModel.accountPickerLabel(for: account)).tag(Optional(account.id))
            }
        }

        if let account = viewModel.selectedAccount {
            Picker("Currency", selection: $viewModel.transactionCurrency) {
                ForEach(account.enabledCurrencies, id: \.self) { currency in
                    Text("\(currency.displayName) (\(currency.symbol))")
                        .tag(currency)
                }
            }
        }

        Picker("Category", selection: $viewModel.categoryID) {
            ForEach(viewModel.filteredCategories) { category in
                Text(category.name).tag(Optional(category.id))
            }
        }
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let repository = PreviewSupport.makeRepository(context: context)
    let viewModel = NewTransactionViewModel(
        defaultMode: .expense,
        preselectedAccountID: nil,
        preselectedCategoryID: nil,
        repository: repository
    )
    viewModel.loadData(defaultCurrency: .eur)
    return IncomeExpenseFieldsView(viewModel: viewModel)
}
