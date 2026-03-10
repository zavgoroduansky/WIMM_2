import Foundation
import SwiftData

@Model
final class Account {
    @Attribute(.unique) var id: UUID
    var name: String
    var primaryCurrency: CurrencyCode
    var enabledCurrenciesRaw: String
    var openingBalanceMinor: Int64
    var iconName: String?
    var createdAt: Date
    var sortOrder: Int

    var accountGroup: AccountGroup

    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction]

    @Transient
    private var enabledCurrenciesCodec: AccountEnabledCurrenciesCoding = AccountEnabledCurrenciesCodec()
    @Transient
    private var balanceCalculator: AccountBalanceCalculating = AccountBalanceCalculator()

    init(
        id: UUID = UUID(),
        name: String,
        primaryCurrency: CurrencyCode,
        enabledCurrencies: [CurrencyCode]? = nil,
        openingBalanceMinor: Int64 = 0,
        iconName: String? = nil,
        createdAt: Date = .now,
        sortOrder: Int = 0,
        accountGroup: AccountGroup,
        enabledCurrenciesCodec: AccountEnabledCurrenciesCoding = AccountEnabledCurrenciesCodec(),
        balanceCalculator: AccountBalanceCalculating = AccountBalanceCalculator()
    ) {
        self.id = id
        self.name = name
        self.primaryCurrency = primaryCurrency
        self.enabledCurrenciesCodec = enabledCurrenciesCodec
        self.balanceCalculator = balanceCalculator
        self.enabledCurrenciesRaw = enabledCurrenciesCodec.encode(
            currencies: enabledCurrencies ?? [primaryCurrency],
            primaryCurrency: primaryCurrency
        )
        self.openingBalanceMinor = openingBalanceMinor
        self.iconName = iconName
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.accountGroup = accountGroup
        self.transactions = []
    }

    var enabledCurrencies: [CurrencyCode] {
        get {
            enabledCurrenciesCodec.decode(
                raw: enabledCurrenciesRaw,
                primaryCurrency: primaryCurrency
            )
        }
        set {
            enabledCurrenciesRaw = enabledCurrenciesCodec.encode(
                currencies: newValue,
                primaryCurrency: primaryCurrency
            )
        }
    }

    func supports(currency: CurrencyCode) -> Bool {
        enabledCurrencies.contains(currency)
    }

    func currentBalanceMinor(for currency: CurrencyCode) -> Int64 {
        balanceCalculator.currentBalanceMinor(
            for: currency,
            primaryCurrency: primaryCurrency,
            openingBalanceMinor: openingBalanceMinor,
            transactions: transactions
        )
    }

    var currentBalanceMinor: Int64 {
        currentBalanceMinor(for: primaryCurrency)
    }

    var balancesByCurrency: [(currency: CurrencyCode, balanceMinor: Int64)] {
        balanceCalculator.balancesByCurrency(
            enabledCurrencies: enabledCurrencies,
            primaryCurrency: primaryCurrency,
            openingBalanceMinor: openingBalanceMinor,
            transactions: transactions
        )
    }
}
