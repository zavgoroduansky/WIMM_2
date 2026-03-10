import SwiftUI

struct TransferFieldsView: View {
    @ObservedObject var viewModel: NewTransactionViewModel

    var body: some View {
        Picker("From", selection: $viewModel.fromAccountID) {
            ForEach(viewModel.orderedAccounts, id: \.id) { account in
                Text(viewModel.accountPickerLabel(for: account)).tag(Optional(account.id))
            }
        }

        if let fromAccount = viewModel.fromAccount {
            Picker("From currency", selection: $viewModel.transferFromCurrency) {
                ForEach(fromAccount.enabledCurrencies, id: \.self) { currency in
                    Text("\(currency.displayName) (\(currency.symbol))")
                        .tag(currency)
                }
            }
        }

        Picker("To", selection: $viewModel.toAccountID) {
            ForEach(viewModel.orderedAccounts, id: \.id) { account in
                Text(viewModel.accountPickerLabel(for: account)).tag(Optional(account.id))
            }
        }

        if let toAccount = viewModel.toAccount {
            Picker("To currency", selection: $viewModel.transferToCurrency) {
                ForEach(toAccount.enabledCurrencies, id: \.self) { currency in
                    Text("\(currency.displayName) (\(currency.symbol))")
                        .tag(currency)
                }
            }
        }

        TextField("Amount to withdraw", text: $viewModel.amount)
            .keyboardType(.decimalPad)

        if viewModel.usesManualAmountTo {
            TextField("Amount to deposit", text: $viewModel.amountTo)
                .keyboardType(.decimalPad)
        } else {
            HStack {
                Text("Amount to deposit")
                Spacer()
                Text(viewModel.amount.isEmpty ? "Same as withdraw" : viewModel.amount)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let repository = PreviewSupport.makeRepository(context: context)
    let viewModel = NewTransactionViewModel(
        defaultMode: .transfer,
        preselectedAccountID: nil,
        preselectedCategoryID: nil,
        repository: repository
    )
    viewModel.loadData(defaultCurrency: .eur)
    return TransferFieldsView(viewModel: viewModel)
}
