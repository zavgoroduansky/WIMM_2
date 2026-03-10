import Foundation
import SwiftData

@MainActor
protocol FinanceRepositorying {
    func fetchAccountGroups() throws -> [AccountGroup]
    func fetchCategories() throws -> [Category]
    func fetchTransactions() throws -> [Transaction]

    @discardableResult
    func createAccountGroup(name: String, sortOrder: Int) -> AccountGroup

    @discardableResult
    func createAccount(
        name: String,
        primaryCurrency: CurrencyCode,
        enabledCurrencies: [CurrencyCode],
        iconName: String?,
        sortOrder: Int,
        accountGroup: AccountGroup
    ) -> Account

    @discardableResult
    func createCategory(name: String, kind: CategoryKind, colorHex: String?) -> Category

    func createIncome(
        amountMinor: Int64,
        account: Account,
        currency: CurrencyCode,
        category: Category?,
        date: Date,
        note: String?
    ) throws

    func createExpense(
        amountMinor: Int64,
        account: Account,
        currency: CurrencyCode,
        category: Category?,
        date: Date,
        note: String?
    ) throws

    func createTransfer(
        fromAccount: Account,
        toAccount: Account,
        fromCurrency: CurrencyCode,
        toCurrency: CurrencyCode,
        amountFromMinor: Int64,
        amountToMinor: Int64?,
        date: Date,
        note: String?
    ) throws

    func delete(_ model: any PersistentModel)
    func save() throws
}

@MainActor
final class SwiftDataFinanceRepository: FinanceRepositorying {
    private let modelContext: ModelContext
    private let transactionService: TransactionServicing

    init(modelContext: ModelContext, transactionService: TransactionServicing) {
        self.modelContext = modelContext
        self.transactionService = transactionService
    }

    convenience init(modelContext: ModelContext) {
        self.init(modelContext: modelContext, transactionService: TransactionService())
    }

    func fetchAccountGroups() throws -> [AccountGroup] {
        let descriptor = FetchDescriptor<AccountGroup>(
            sortBy: [SortDescriptor(\AccountGroup.sortOrder), SortDescriptor(\AccountGroup.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchCategories() throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\Category.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchTransactions() throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\Transaction.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    @discardableResult
    func createAccountGroup(name: String, sortOrder: Int) -> AccountGroup {
        let group = AccountGroup(name: name, sortOrder: sortOrder)
        modelContext.insert(group)
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
            openingBalanceMinor: 0,
            iconName: iconName,
            sortOrder: sortOrder,
            accountGroup: accountGroup
        )
        modelContext.insert(account)
        return account
    }

    @discardableResult
    func createCategory(name: String, kind: CategoryKind, colorHex: String?) -> Category {
        let category = Category(name: name, kind: kind, colorHex: colorHex)
        modelContext.insert(category)
        return category
    }

    func createIncome(
        amountMinor: Int64,
        account: Account,
        currency: CurrencyCode,
        category: Category?,
        date: Date,
        note: String?
    ) throws {
        try transactionService.createIncome(
            amountMinor: amountMinor,
            account: account,
            currency: currency,
            category: category,
            date: date,
            note: note,
            in: modelContext
        )
    }

    func createExpense(
        amountMinor: Int64,
        account: Account,
        currency: CurrencyCode,
        category: Category?,
        date: Date,
        note: String?
    ) throws {
        try transactionService.createExpense(
            amountMinor: amountMinor,
            account: account,
            currency: currency,
            category: category,
            date: date,
            note: note,
            in: modelContext
        )
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
        try transactionService.createTransfer(
            fromAccount: fromAccount,
            toAccount: toAccount,
            fromCurrency: fromCurrency,
            toCurrency: toCurrency,
            amountFromMinor: amountFromMinor,
            amountToMinor: amountToMinor,
            date: date,
            note: note,
            in: modelContext
        )
    }

    func delete(_ model: any PersistentModel) {
        modelContext.delete(model)
    }

    func save() throws {
        try modelContext.save()
    }
}
