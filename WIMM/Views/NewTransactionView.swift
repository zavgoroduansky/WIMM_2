import SwiftUI
import SwiftData

struct NewTransactionView: View {
    enum TransactionMode: String, CaseIterable, Identifiable {
        case expense
        case income
        case transfer

        var id: String { rawValue }

        var title: String {
            switch self {
            case .expense: return "Expense"
            case .income: return "Income"
            case .transfer: return "Transfer"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\AccountGroup.sortOrder), SortDescriptor(\AccountGroup.name)])
    private var accountGroups: [AccountGroup]
    @Query(sort: [SortDescriptor(\Category.name)])
    private var categories: [Category]

    @AppStorage("defaultCurrency") private var defaultCurrencyRaw = CurrencyCode.eur.rawValue

    @State private var mode: TransactionMode
    @State private var amount = ""
    @State private var amountTo = ""
    @State private var accountID: UUID?
    @State private var categoryID: UUID?
    @State private var fromAccountID: UUID?
    @State private var toAccountID: UUID?
    @State private var transactionCurrency: CurrencyCode = .eur
    @State private var transferFromCurrency: CurrencyCode = .eur
    @State private var transferToCurrency: CurrencyCode = .eur
    @State private var date = Date()
    @State private var note = ""
    @State private var errorText: String?

    private let preselectedAccountID: UUID?
    private let preselectedCategoryID: UUID?

    init(
        defaultMode: TransactionMode = .expense,
        preselectedAccountID: UUID? = nil,
        preselectedCategoryID: UUID? = nil
    ) {
        _mode = State(initialValue: defaultMode)
        self.preselectedAccountID = preselectedAccountID
        self.preselectedCategoryID = preselectedCategoryID
    }

    var body: some View {
        NavigationStack {
            Group {
                if orderedAccounts.isEmpty || (mode != .transfer && filteredCategories.isEmpty) {
                    ContentUnavailableView(
                        "Not Enough Data",
                        systemImage: "tray",
                        description: Text("Create account groups, accounts, and categories in Settings before adding transactions.")
                    )
                } else {
                    Form {
                        Picker("Type", selection: $mode) {
                            ForEach(TransactionMode.allCases) { item in
                                Text(item.title).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)

                        if mode == .transfer {
                            transferFields
                        } else {
                            incomeExpenseFields
                        }

                        DatePicker("Date", selection: $date, displayedComponents: [.date])
                        TextField("Note", text: $note, axis: .vertical)
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
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: preload)
            .onChange(of: mode) { _, _ in preload() }
            .onChange(of: accountID) { _, _ in syncSingleCurrencySelection() }
            .onChange(of: fromAccountID) { _, _ in syncTransferCurrencySelection() }
            .onChange(of: toAccountID) { _, _ in syncTransferCurrencySelection() }
            .onChange(of: transferFromCurrency) { _, _ in
                if !usesManualAmountTo {
                    amountTo = ""
                }
            }
            .onChange(of: transferToCurrency) { _, _ in
                if !usesManualAmountTo {
                    amountTo = ""
                }
            }
            .alert("Cannot Save", isPresented: Binding(
                get: { errorText != nil },
                set: { _ in errorText = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorText ?? "Unknown error")
            }
        }
    }

    @ViewBuilder
    private var incomeExpenseFields: some View {
        TextField("Amount", text: $amount)
            .keyboardType(.decimalPad)

        Picker("Account", selection: $accountID) {
            ForEach(orderedAccounts) { account in
                Text(accountPickerLabel(for: account)).tag(Optional(account.id))
            }
        }

        if let account = selectedAccount {
            Picker("Currency", selection: $transactionCurrency) {
                ForEach(account.enabledCurrencies, id: \.self) { currency in
                    Text("\(currency.displayName) (\(currency.symbol))")
                        .tag(currency)
                }
            }
        }

        Picker("Category", selection: $categoryID) {
            ForEach(filteredCategories) { category in
                Text(category.name).tag(Optional(category.id))
            }
        }
    }

    @ViewBuilder
    private var transferFields: some View {
        Picker("From", selection: $fromAccountID) {
            ForEach(orderedAccounts) { account in
                Text(accountPickerLabel(for: account)).tag(Optional(account.id))
            }
        }

        if let fromAccount {
            Picker("From currency", selection: $transferFromCurrency) {
                ForEach(fromAccount.enabledCurrencies, id: \.self) { currency in
                    Text("\(currency.displayName) (\(currency.symbol))")
                        .tag(currency)
                }
            }
        }

        Picker("To", selection: $toAccountID) {
            ForEach(orderedAccounts) { account in
                Text(accountPickerLabel(for: account)).tag(Optional(account.id))
            }
        }

        if let toAccount {
            Picker("To currency", selection: $transferToCurrency) {
                ForEach(toAccount.enabledCurrencies, id: \.self) { currency in
                    Text("\(currency.displayName) (\(currency.symbol))")
                        .tag(currency)
                }
            }
        }

        TextField("Amount to withdraw", text: $amount)
            .keyboardType(.decimalPad)

        if usesManualAmountTo {
            TextField("Amount to deposit", text: $amountTo)
                .keyboardType(.decimalPad)
        } else {
            HStack {
                Text("Amount to deposit")
                Spacer()
                Text(amount.isEmpty ? "Same as withdraw" : amount)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var selectedAccount: Account? {
        orderedAccounts.first { $0.id == accountID }
    }

    private var selectedCategory: Category? {
        filteredCategories.first { $0.id == categoryID }
    }

    private var fromAccount: Account? {
        orderedAccounts.first { $0.id == fromAccountID }
    }

    private var toAccount: Account? {
        orderedAccounts.first { $0.id == toAccountID }
    }

    private var defaultCurrency: CurrencyCode {
        CurrencyCode(rawValue: defaultCurrencyRaw) ?? .eur
    }

    private var orderedAccounts: [Account] {
        var result: [Account] = []
        let sortedGroups = accountGroups.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder { return lhs.name < rhs.name }
            return lhs.sortOrder < rhs.sortOrder
        }

        for group in sortedGroups {
            let groupAccounts = group.accounts.sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder { return lhs.name < rhs.name }
                return lhs.sortOrder < rhs.sortOrder
            }
            result.append(contentsOf: groupAccounts)
        }
        return result
    }

    private var usesManualAmountTo: Bool {
        transferFromCurrency != transferToCurrency
    }

    private var canSave: Bool {
        switch mode {
        case .income, .expense:
            guard let parsed = Money.minor(fromInput: amount), parsed > 0 else { return false }
            guard selectedAccount != nil, selectedCategory != nil else { return false }
            return true
        case .transfer:
            guard let fromMinor = Money.minor(fromInput: amount), fromMinor > 0 else { return false }
            guard let fromAccount, let toAccount, fromAccount.id != toAccount.id else { return false }
            if usesManualAmountTo {
                guard let toMinor = Money.minor(fromInput: amountTo), toMinor > 0 else { return false }
            }
            return true
        }
    }

    private func preload() {
        if accountID == nil {
            accountID = preselectedAccountID ?? orderedAccounts.first?.id
        }
        if fromAccountID == nil {
            fromAccountID = preselectedAccountID ?? orderedAccounts.first?.id
        }
        if toAccountID == nil {
            toAccountID = orderedAccounts.dropFirst().first?.id ?? orderedAccounts.first?.id
        }

        syncSingleCurrencySelection()
        syncTransferCurrencySelection()

        if let preselectedCategoryID,
           filteredCategories.contains(where: { $0.id == preselectedCategoryID }) {
            categoryID = preselectedCategoryID
        }

        if categoryID == nil || !filteredCategories.contains(where: { $0.id == categoryID }) {
            categoryID = filteredCategories.first?.id
        }
    }

    private func syncSingleCurrencySelection() {
        guard let selectedAccount else { return }
        if selectedAccount.enabledCurrencies.contains(defaultCurrency) {
            transactionCurrency = defaultCurrency
        } else if !selectedAccount.enabledCurrencies.contains(transactionCurrency),
                  let first = selectedAccount.enabledCurrencies.first {
            transactionCurrency = first
        }
    }

    private func syncTransferCurrencySelection() {
        if let fromAccount {
            if fromAccount.enabledCurrencies.contains(defaultCurrency) {
                transferFromCurrency = defaultCurrency
            } else if !fromAccount.enabledCurrencies.contains(transferFromCurrency),
                      let first = fromAccount.enabledCurrencies.first {
                transferFromCurrency = first
            }
        }

        if let toAccount {
            if toAccount.enabledCurrencies.contains(defaultCurrency) {
                transferToCurrency = defaultCurrency
            } else if !toAccount.enabledCurrencies.contains(transferToCurrency),
                      let first = toAccount.enabledCurrencies.first {
                transferToCurrency = first
            }
        }
    }

    private func save() {
        do {
            switch mode {
            case .income:
                guard let amountMinor = Money.minor(fromInput: amount),
                      let account = selectedAccount,
                      let category = selectedCategory else {
                    throw TransactionServiceError.invalidAmount
                }

                try TransactionService.createIncome(
                    amountMinor: amountMinor,
                    account: account,
                    currency: transactionCurrency,
                    category: category,
                    date: date,
                    note: note.isEmpty ? nil : note,
                    in: modelContext
                )
            case .expense:
                guard let amountMinor = Money.minor(fromInput: amount),
                      let account = selectedAccount,
                      let category = selectedCategory else {
                    throw TransactionServiceError.invalidAmount
                }

                try TransactionService.createExpense(
                    amountMinor: amountMinor,
                    account: account,
                    currency: transactionCurrency,
                    category: category,
                    date: date,
                    note: note.isEmpty ? nil : note,
                    in: modelContext
                )
            case .transfer:
                guard let fromAccount,
                      let toAccount,
                      let amountFromMinor = Money.minor(fromInput: amount) else {
                    throw TransactionServiceError.invalidAmount
                }

                let amountToMinor = usesManualAmountTo ? Money.minor(fromInput: amountTo) : nil

                try TransactionService.createTransfer(
                    fromAccount: fromAccount,
                    toAccount: toAccount,
                    fromCurrency: transferFromCurrency,
                    toCurrency: transferToCurrency,
                    amountFromMinor: amountFromMinor,
                    amountToMinor: amountToMinor,
                    date: date,
                    note: note.isEmpty ? nil : note,
                    in: modelContext
                )
            }
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }

    private var filteredCategories: [Category] {
        let kind: CategoryKind
        switch mode {
        case .income:
            kind = .income
        case .expense:
            kind = .expense
        case .transfer:
            return []
        }

        return categories
            .filter { $0.kind == kind }
            .sorted { $0.name < $1.name }
    }

    private func accountPickerLabel(for account: Account) -> String {
        "\(account.accountGroup.name) • \(account.name)"
    }
}
