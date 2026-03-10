import Foundation
import Combine

@MainActor
final class NewTransactionViewModel: ObservableObject {
    typealias TransactionMode = NewTransactionUseCase.TransactionMode

    @Published var mode: TransactionMode
    @Published var amount = ""
    @Published var amountTo = ""
    @Published var accountID: UUID?
    @Published var categoryID: UUID?
    @Published var fromAccountID: UUID?
    @Published var toAccountID: UUID?
    @Published var transactionCurrency: CurrencyCode = .eur
    @Published var transferFromCurrency: CurrencyCode = .eur
    @Published var transferToCurrency: CurrencyCode = .eur
    @Published var date = Date()
    @Published var note = ""
    @Published var errorText: String?

    private(set) var accountGroups: [AccountGroup] = []
    private(set) var categories: [Category] = []

    private let preselectedAccountID: UUID?
    private let preselectedCategoryID: UUID?
    private let useCase: NewTransactionUseCase

    private var defaultCurrency: CurrencyCode = .eur

    init(
        defaultMode: TransactionMode = .expense,
        preselectedAccountID: UUID? = nil,
        preselectedCategoryID: UUID? = nil,
        repository: FinanceRepositorying
    ) {
        self.mode = defaultMode
        self.preselectedAccountID = preselectedAccountID
        self.preselectedCategoryID = preselectedCategoryID
        self.useCase = NewTransactionUseCase(repository: repository)
    }

    var orderedAccounts: [Account] {
        var result: [Account] = []
        let sortedGroups = accountGroups.sortedByOrderThenName()

        for group in sortedGroups {
            let groupAccounts = group.accounts.sortedByOrderThenName()
            result.append(contentsOf: groupAccounts)
        }
        return result
    }

    var selectedAccount: Account? {
        orderedAccounts.first { $0.id == accountID }
    }

    var selectedCategory: Category? {
        filteredCategories.first { $0.id == categoryID }
    }

    var fromAccount: Account? {
        orderedAccounts.first { $0.id == fromAccountID }
    }

    var toAccount: Account? {
        orderedAccounts.first { $0.id == toAccountID }
    }

    var filteredCategories: [Category] {
        let kind: CategoryKind = mode == .income ? .income : .expense
        return categories
            .filter { $0.kind == kind }
            .sortedByName()
    }

    var usesManualAmountTo: Bool {
        transferFromCurrency != transferToCurrency
    }

    var hasRequiredData: Bool {
        if orderedAccounts.isEmpty {
            return false
        }
        if mode != .transfer && filteredCategories.isEmpty {
            return false
        }
        return true
    }

    var canSave: Bool {
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

    func updateData(
        accountGroups: [AccountGroup],
        categories: [Category],
        defaultCurrency: CurrencyCode
    ) {
        self.accountGroups = accountGroups
        self.categories = categories
        self.defaultCurrency = defaultCurrency
        applyDefaultsAndSync()
    }

    func loadData(defaultCurrency: CurrencyCode) {
        let data = useCase.loadData()
        let groups = data.groups
        let categories = data.categories
        updateData(accountGroups: groups, categories: categories, defaultCurrency: defaultCurrency)
    }

    func handleModeChange() {
        applyDefaultsAndSync()
    }

    func handleAccountChange() {
        syncSingleCurrencySelection()
    }

    func handleTransferAccountsChange() {
        syncTransferCurrencySelection()
    }

    func handleTransferCurrenciesChange() {
        if !usesManualAmountTo {
            amountTo = ""
        }
    }

    func accountPickerLabel(for account: Account) -> String {
        "\(account.accountGroup.name) • \(account.name)"
    }

    @discardableResult
    func save() -> Bool {
        do {
            let input = NewTransactionUseCase.Input(
                mode: mode,
                amount: amount,
                amountTo: amountTo,
                selectedAccount: selectedAccount,
                selectedCategory: selectedCategory,
                fromAccount: fromAccount,
                toAccount: toAccount,
                transactionCurrency: transactionCurrency,
                transferFromCurrency: transferFromCurrency,
                transferToCurrency: transferToCurrency,
                date: date,
                note: note,
                usesManualAmountTo: usesManualAmountTo
            )
            try useCase.save(input: input)

            errorText = nil
            return true
        } catch {
            errorText = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return false
        }
    }

    private func applyDefaultsAndSync() {
        if mode == .transfer {
            if fromAccountID == nil || !orderedAccounts.contains(where: { $0.id == fromAccountID }) {
                fromAccountID = preselectedAccountID ?? orderedAccounts.first?.id
            }

            if toAccountID == nil || !orderedAccounts.contains(where: { $0.id == toAccountID }) {
                toAccountID = orderedAccounts.first(where: { $0.id != fromAccountID })?.id
            }

            if toAccountID == fromAccountID {
                toAccountID = orderedAccounts.first(where: { $0.id != fromAccountID })?.id
            }

            syncTransferCurrencySelection()
        } else {
            if accountID == nil || !orderedAccounts.contains(where: { $0.id == accountID }) {
                accountID = preselectedAccountID ?? orderedAccounts.first?.id
            }

            let categoryIsValid = filteredCategories.contains(where: { $0.id == categoryID })
            if !categoryIsValid {
                if let preselectedCategoryID,
                   filteredCategories.contains(where: { $0.id == preselectedCategoryID }) {
                    categoryID = preselectedCategoryID
                } else {
                    categoryID = filteredCategories.first?.id
                }
            }

            syncSingleCurrencySelection()
        }
    }

    private func syncSingleCurrencySelection() {
        guard let account = selectedAccount else {
            transactionCurrency = defaultCurrency
            return
        }

        if account.supports(currency: transactionCurrency) {
            return
        }

        if account.supports(currency: defaultCurrency) {
            transactionCurrency = defaultCurrency
        } else {
            transactionCurrency = account.enabledCurrencies.first ?? account.primaryCurrency
        }
    }

    private func syncTransferCurrencySelection() {
        if let fromAccount {
            if !fromAccount.supports(currency: transferFromCurrency) {
                if fromAccount.supports(currency: defaultCurrency) {
                    transferFromCurrency = defaultCurrency
                } else {
                    transferFromCurrency = fromAccount.enabledCurrencies.first ?? fromAccount.primaryCurrency
                }
            }
        } else {
            transferFromCurrency = defaultCurrency
        }

        if let toAccount {
            if !toAccount.supports(currency: transferToCurrency) {
                if toAccount.supports(currency: defaultCurrency) {
                    transferToCurrency = defaultCurrency
                } else {
                    transferToCurrency = toAccount.enabledCurrencies.first ?? toAccount.primaryCurrency
                }
            }
        } else {
            transferToCurrency = defaultCurrency
        }
    }

}
