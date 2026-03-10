import SwiftUI
import SwiftData

@MainActor
enum PreviewSupport {
    static func makeContext() -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: AccountGroup.self,
            Account.self,
            Category.self,
            Transaction.self,
            configurations: config
        )
        let context = ModelContext(container)
        seed(context: context)
        return context
    }

    static func makeDependencies() -> AppDependencies {
        AppDependencies()
    }

    static func makeRepository(context: ModelContext) -> FinanceRepositorying {
        SwiftDataFinanceRepository(modelContext: context)
    }

    static func makeBalanceService() -> AccountGroupBalanceServicing {
        AccountGroupBalanceService(rateProvider: PreviewRateProvider())
    }

    private static func seed(context: ModelContext) {
        let group = AccountGroup(name: "Cash", sortOrder: 0)
        let account = Account(
            name: "Wallet",
            primaryCurrency: .eur,
            enabledCurrencies: [.eur, .uah],
            sortOrder: 0,
            accountGroup: group
        )
        let category = Category(name: "Food", kind: .expense, colorHex: CategoryColorPalette.defaultHex)
        let incomeCategory = Category(name: "Salary", kind: .income, colorHex: "#3B82F6")

        context.insert(group)
        context.insert(account)
        context.insert(category)
        context.insert(incomeCategory)

        let tx = Transaction(
            kind: .expense,
            amountMinor: 1250,
            currency: .eur,
            date: .now,
            note: "Lunch",
            account: account,
            category: category
        )
        context.insert(tx)
    }
}

struct PreviewRateProvider: ExchangeRateProvider {
    func rate(from: CurrencyCode, to: CurrencyCode, on date: Date?) async throws -> Decimal {
        if from == to { return 1 }
        return 1
    }
}
