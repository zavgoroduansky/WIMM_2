import Foundation
import SwiftData

enum CurrencyCode: String, Codable, CaseIterable, Identifiable {
    case eur
    case usd
    case uah

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .eur: return "€"
        case .usd: return "$"
        case .uah: return "₴"
        }
    }

    var displayName: String {
        switch self {
        case .eur: return "Euro"
        case .usd: return "US Dollar"
        case .uah: return "Ukrainian Hryvnia"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .eur: return "en_IE"
        case .usd: return "en_US"
        case .uah: return "uk_UA"
        }
    }
}

enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case income
    case expense

    var id: String { rawValue }
}

enum CategoryKind: String, Codable, CaseIterable, Identifiable {
    case income
    case expense

    var id: String { rawValue }

    var title: String {
        switch self {
        case .income: return "Income"
        case .expense: return "Expense"
        }
    }
}

@Model
final class AccountGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \Account.accountGroup)
    var accounts: [Account]

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.accounts = []
    }
}

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

    init(
        id: UUID = UUID(),
        name: String,
        primaryCurrency: CurrencyCode,
        enabledCurrencies: [CurrencyCode]? = nil,
        openingBalanceMinor: Int64 = 0,
        iconName: String? = nil,
        createdAt: Date = .now,
        sortOrder: Int = 0,
        accountGroup: AccountGroup
    ) {
        self.id = id
        self.name = name
        self.primaryCurrency = primaryCurrency
        let resolvedEnabled = (enabledCurrencies?.isEmpty == false) ? enabledCurrencies! : [primaryCurrency]
        self.enabledCurrenciesRaw = resolvedEnabled.map(\.rawValue).joined(separator: ",")
        self.openingBalanceMinor = openingBalanceMinor
        self.iconName = iconName
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.accountGroup = accountGroup
        self.transactions = []
    }

    var enabledCurrencies: [CurrencyCode] {
        get {
            let parsed = enabledCurrenciesRaw
                .split(separator: ",")
                .compactMap { CurrencyCode(rawValue: String($0)) }

            if parsed.isEmpty {
                return [primaryCurrency]
            }
            if parsed.contains(primaryCurrency) {
                return parsed
            }
            return [primaryCurrency] + parsed
        }
        set {
            var values: [CurrencyCode] = []
            for currency in CurrencyCode.allCases {
                if newValue.contains(currency) {
                    values.append(currency)
                }
            }
            if !values.contains(primaryCurrency) {
                values.insert(primaryCurrency, at: 0)
            }
            enabledCurrenciesRaw = values.map(\.rawValue).joined(separator: ",")
        }
    }

    func supports(currency: CurrencyCode) -> Bool {
        enabledCurrencies.contains(currency)
    }

    func currentBalanceMinor(for currency: CurrencyCode) -> Int64 {
        let incomes = transactions
            .filter { $0.kind == .income && $0.currency == currency }
            .reduce(Int64.zero) { $0 + $1.amountMinor }
        let expenses = transactions
            .filter { $0.kind == .expense && $0.currency == currency }
            .reduce(Int64.zero) { $0 + $1.amountMinor }

        let opening = currency == primaryCurrency ? openingBalanceMinor : 0
        return opening + incomes - expenses
    }

    var currentBalanceMinor: Int64 {
        currentBalanceMinor(for: primaryCurrency)
    }

    var balancesByCurrency: [(currency: CurrencyCode, balanceMinor: Int64)] {
        enabledCurrencies.map { currency in
            (currency, currentBalanceMinor(for: currency))
        }
    }
}

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var kind: CategoryKind
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]

    init(
        id: UUID = UUID(),
        name: String,
        kind: CategoryKind = .expense,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.createdAt = createdAt
        self.transactions = []
    }
}

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var kind: TransactionKind
    var amountMinor: Int64
    var currency: CurrencyCode
    var date: Date
    var note: String?
    var transferGroupId: UUID?
    var createdAt: Date

    var account: Account
    var category: Category?

    init(
        id: UUID = UUID(),
        kind: TransactionKind,
        amountMinor: Int64,
        currency: CurrencyCode,
        date: Date = .now,
        note: String? = nil,
        transferGroupId: UUID? = nil,
        createdAt: Date = .now,
        account: Account,
        category: Category? = nil
    ) {
        self.id = id
        self.kind = kind
        self.amountMinor = amountMinor
        self.currency = currency
        self.date = date
        self.note = note
        self.transferGroupId = transferGroupId
        self.createdAt = createdAt
        self.account = account
        self.category = category
    }
}
