import Foundation
import SwiftData
@testable import WIMM

@MainActor
final class MockFinanceRepository: FinanceRepositorying {
    private(set) var accountGroups: [AccountGroup] = []
    private(set) var categories: [WIMM.Category] = []
    private(set) var transactions: [Transaction] = []

    private(set) var createIncomeCalls = 0
    private(set) var createExpenseCalls = 0
    private(set) var createTransferCalls = 0
    private(set) var deleteCalls = 0
    private(set) var saveCalls = 0

    private(set) var lastIncomeAmountMinor: Int64?
    private(set) var lastIncomeCurrency: CurrencyCode?
    private(set) var lastIncomeCategoryID: UUID?
    private(set) var lastIncomeNote: String?
    private(set) var lastExpenseAmountMinor: Int64?
    private(set) var lastExpenseCurrency: CurrencyCode?
    private(set) var lastExpenseCategoryID: UUID?
    private(set) var lastExpenseNote: String?
    private(set) var lastTransferFromAmountMinor: Int64?
    private(set) var lastTransferToAmountMinor: Int64?
    private(set) var lastTransferFromCurrency: CurrencyCode?
    private(set) var lastTransferToCurrency: CurrencyCode?

    func seed(groups: [AccountGroup], categories: [WIMM.Category], transactions: [Transaction]) {
        self.accountGroups = groups
        self.categories = categories
        self.transactions = transactions
    }

    func fetchAccountGroups() throws -> [AccountGroup] {
        accountGroups
    }

    func fetchCategories() throws -> [WIMM.Category] {
        categories
    }

    func fetchTransactions() throws -> [Transaction] {
        transactions
    }

    @discardableResult
    func createAccountGroup(name: String, sortOrder: Int) -> AccountGroup {
        let group = AccountGroup(name: name, sortOrder: sortOrder)
        accountGroups.append(group)
        return group
    }

    @discardableResult
    func createAccount(
        name: String,
        primaryCurrency: CurrencyCode,
        enabledCurrencies: [CurrencyCode],
        iconName: String?,
        sortOrder: Int,
        accountGroup: AccountGroup
    ) -> Account {
        let account = Account(
            name: name,
            primaryCurrency: primaryCurrency,
            enabledCurrencies: enabledCurrencies,
            iconName: iconName,
            sortOrder: sortOrder,
            accountGroup: accountGroup
        )
        accountGroups = accountGroups.map { group in
            if group.id == accountGroup.id {
                group.accounts.append(account)
            }
            return group
        }
        return account
    }

    @discardableResult
    func createCategory(name: String, kind: CategoryKind, colorHex: String?) -> WIMM.Category {
        let category = WIMM.Category(name: name, kind: kind, colorHex: colorHex)
        categories.append(category)
        return category
    }

    func createIncome(
        amountMinor: Int64,
        account: Account,
        currency: CurrencyCode,
        category: WIMM.Category?,
        date: Date,
        note: String?
    ) throws {
        createIncomeCalls += 1
        lastIncomeAmountMinor = amountMinor
        lastIncomeCurrency = currency
        lastIncomeCategoryID = category?.id
        lastIncomeNote = note
        let tx = Transaction(kind: .income, amountMinor: amountMinor, currency: currency, date: date, note: note, account: account, category: category)
        transactions.append(tx)
    }

    func createExpense(
        amountMinor: Int64,
        account: Account,
        currency: CurrencyCode,
        category: WIMM.Category?,
        date: Date,
        note: String?
    ) throws {
        createExpenseCalls += 1
        lastExpenseAmountMinor = amountMinor
        lastExpenseCurrency = currency
        lastExpenseCategoryID = category?.id
        lastExpenseNote = note
        let tx = Transaction(kind: .expense, amountMinor: amountMinor, currency: currency, date: date, note: note, account: account, category: category)
        transactions.append(tx)
    }

    func createTransfer(
        fromAccount: Account,
        toAccount: Account,
        fromCurrency: CurrencyCode,
        toCurrency: CurrencyCode,
        amountFromMinor: Int64,
        amountToMinor: Int64?,
        date: Date,
        note: String?
    ) throws {
        createTransferCalls += 1
        lastTransferFromAmountMinor = amountFromMinor
        lastTransferToAmountMinor = amountToMinor ?? amountFromMinor
        lastTransferFromCurrency = fromCurrency
        lastTransferToCurrency = toCurrency
        let groupID = UUID()
        let outflow = Transaction(
            kind: .expense,
            amountMinor: amountFromMinor,
            currency: fromCurrency,
            date: date,
            note: note,
            transferGroupId: groupID,
            account: fromAccount
        )
        let inflowAmount = amountToMinor ?? amountFromMinor
        let inflow = Transaction(
            kind: .income,
            amountMinor: inflowAmount,
            currency: toCurrency,
            date: date,
            note: note,
            transferGroupId: groupID,
            account: toAccount
        )
        transactions.append(outflow)
        transactions.append(inflow)
    }

    func delete(_ model: any PersistentModel) {
        deleteCalls += 1
        if let account = model as? Account {
            transactions.removeAll { $0.account.id == account.id }
            for group in accountGroups {
                group.accounts.removeAll { $0.id == account.id }
            }
        } else if let category = model as? WIMM.Category {
            transactions.removeAll { $0.category?.id == category.id }
            categories.removeAll { $0.id == category.id }
        } else if let group = model as? AccountGroup {
            let accountIDs = group.accounts.map(\.id)
            transactions.removeAll { accountIDs.contains($0.account.id) }
            accountGroups.removeAll { $0.id == group.id }
        } else if let transaction = model as? Transaction {
            transactions.removeAll { $0.id == transaction.id }
        }
    }

    func save() throws {
        saveCalls += 1
    }
}
