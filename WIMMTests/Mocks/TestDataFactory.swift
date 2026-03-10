import Foundation
import SwiftData
@testable import WIMM

enum TestDataFactory {
    static func makeInMemoryContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: AccountGroup.self,
            Account.self,
            WIMM.Category.self,
            Transaction.self,
            configurations: configuration
        )
        return ModelContext(container)
    }

    static func makeAccountGroup(name: String = "Group", sortOrder: Int = 0) -> AccountGroup {
        AccountGroup(name: name, sortOrder: sortOrder)
    }

    static func makeAccount(
        name: String = "Account",
        primaryCurrency: CurrencyCode = .eur,
        enabledCurrencies: [CurrencyCode]? = nil,
        sortOrder: Int = 0,
        accountGroup: AccountGroup
    ) -> Account {
        Account(
            name: name,
            primaryCurrency: primaryCurrency,
            enabledCurrencies: enabledCurrencies,
            sortOrder: sortOrder,
            accountGroup: accountGroup
        )
    }

    static func makeCategory(name: String = "Category", kind: CategoryKind = .expense) -> WIMM.Category {
        WIMM.Category(name: name, kind: kind)
    }
}
