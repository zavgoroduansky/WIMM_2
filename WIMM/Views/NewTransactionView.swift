import SwiftUI
import SwiftData

struct NewTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\AccountGroup.sortOrder), SortDescriptor(\AccountGroup.name)])
    private var accountGroups: [AccountGroup]
    @Query(sort: [SortDescriptor(\Category.name)])
    private var categories: [Category]

    @AppStorage("defaultCurrency") private var defaultCurrencyRaw = CurrencyCode.eur.rawValue

    @StateObject private var viewModel: NewTransactionViewModel

    init(
        defaultMode: NewTransactionViewModel.TransactionMode = .expense,
        preselectedAccountID: UUID? = nil,
        preselectedCategoryID: UUID? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: NewTransactionViewModel(
                defaultMode: defaultMode,
                preselectedAccountID: preselectedAccountID,
                preselectedCategoryID: preselectedCategoryID,
                transactionService: TransactionService()
            )
        )
    }

    init(
        defaultMode: NewTransactionViewModel.TransactionMode = .expense,
        preselectedAccountID: UUID? = nil,
        preselectedCategoryID: UUID? = nil,
        transactionService: TransactionServicing
    ) {
        _viewModel = StateObject(
            wrappedValue: NewTransactionViewModel(
                defaultMode: defaultMode,
                preselectedAccountID: preselectedAccountID,
                preselectedCategoryID: preselectedCategoryID,
                transactionService: transactionService
            )
        )
    }

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
                        Picker("Type", selection: $viewModel.mode) {
                            ForEach(NewTransactionViewModel.TransactionMode.allCases) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)

                        if viewModel.mode == .transfer {
                            transferFields
                        } else {
                            incomeExpenseFields
                        }

                        DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date])
                        TextField("Note", text: $viewModel.note, axis: .vertical)
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
            .onAppear(perform: syncViewModelData)
            .onChange(of: accountGroups) { _, _ in syncViewModelData() }
            .onChange(of: categories) { _, _ in syncViewModelData() }
            .onChange(of: defaultCurrencyRaw) { _, _ in syncViewModelData() }
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

    @ViewBuilder
    private var incomeExpenseFields: some View {
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

    @ViewBuilder
    private var transferFields: some View {
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

    private func save() {
        if viewModel.save(in: modelContext) {
            dismiss()
        }
    }

    private func syncViewModelData() {
        viewModel.updateData(
            accountGroups: accountGroups,
            categories: categories,
            defaultCurrency: CurrencyCode(rawValue: defaultCurrencyRaw) ?? .eur
        )
    }
}
