import SwiftUI
import SwiftData

struct NewTransactionView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("defaultCurrency") private var defaultCurrencyRaw = CurrencyCode.eur.rawValue

    @ObservedObject var viewModel: NewTransactionViewModel
    let makeRepository: () -> FinanceRepositorying

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.hasRequiredData {
                    ContentUnavailableView(
                        "Not Enough Data",
                        systemImage: "tray",
                        description: Text("Create account groups, accounts, and categories in Settings before adding transactions.")
                    )
                } else {
                    Form {
                        TransactionTypePickerView(mode: $viewModel.mode)

                        if viewModel.mode == .transfer {
                            TransferFieldsView(viewModel: viewModel)
                        } else {
                            IncomeExpenseFieldsView(viewModel: viewModel)
                        }

                        TransactionMetaSectionView(date: $viewModel.date, note: $viewModel.note)
                    }
                }
            }
            .navigationTitle("New Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!viewModel.canSave)
                }
            }
            .onAppear(perform: loadData)
            .onChange(of: defaultCurrencyRaw) { _, _ in loadData() }
            .onChange(of: viewModel.mode) { _, _ in viewModel.handleModeChange() }
            .onChange(of: viewModel.accountID) { _, _ in viewModel.handleAccountChange() }
            .onChange(of: viewModel.fromAccountID) { _, _ in viewModel.handleTransferAccountsChange() }
            .onChange(of: viewModel.toAccountID) { _, _ in viewModel.handleTransferAccountsChange() }
            .onChange(of: viewModel.transferFromCurrency) { _, _ in viewModel.handleTransferCurrenciesChange() }
            .onChange(of: viewModel.transferToCurrency) { _, _ in viewModel.handleTransferCurrenciesChange() }
            .alert("Cannot Save", isPresented: Binding(
                get: { viewModel.errorText != nil },
                set: { _ in viewModel.errorText = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorText ?? "Unknown error")
            }
        }
    }

    private func save() {
        if viewModel.save(using: makeRepository()) {
            dismiss()
        }
    }

    private func loadData() {
        viewModel.loadData(
            defaultCurrency: CurrencyCode(rawValue: defaultCurrencyRaw) ?? .eur,
            using: makeRepository()
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let repository = PreviewSupport.makeRepository(context: context)
    let viewModel = NewTransactionViewModel(
        defaultMode: .expense,
        preselectedAccountID: nil,
        preselectedCategoryID: nil,
        transactionService: TransactionService()
    )

    return NewTransactionView(
        viewModel: viewModel,
        makeRepository: { repository }
    )
}
