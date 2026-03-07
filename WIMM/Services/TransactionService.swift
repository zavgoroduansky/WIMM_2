import Foundation
import SwiftData

enum TransactionServiceError: LocalizedError {
    case invalidAmount
    case sameTransferAccounts
    case invalidCurrencyForTransaction
    case currencyNotEnabledForAccount

    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Amount must be greater than zero."
        case .sameTransferAccounts:
            return "Transfer accounts must be different."
        case .invalidCurrencyForTransaction:
            return "Transaction currency must match account currency."
        case .currencyNotEnabledForAccount:
            return "Selected currency is not enabled for this account."
        }
    }
}

enum TransactionService {
    static func createIncome(
        amountMinor: Int64,
        account: Account,
        currency: CurrencyCode,
        category: Category?,
        date: Date = .now,
        note: String? = nil,
        in modelContext: ModelContext
    ) throws {
        try validateAmount(amountMinor)
        try validateAccountCurrency(account: account, currency: currency)

        let transaction = Transaction(
            kind: .income,
            amountMinor: amountMinor,
            currency: currency,
            date: date,
            note: note,
            account: account,
            category: category
        )
        modelContext.insert(transaction)
        try modelContext.save()
    }

    static func createExpense(
        amountMinor: Int64,
        account: Account,
        currency: CurrencyCode,
        category: Category?,
        date: Date = .now,
        note: String? = nil,
        in modelContext: ModelContext
    ) throws {
        try validateAmount(amountMinor)
        try validateAccountCurrency(account: account, currency: currency)

        let transaction = Transaction(
            kind: .expense,
            amountMinor: amountMinor,
            currency: currency,
            date: date,
            note: note,
            account: account,
            category: category
        )
        modelContext.insert(transaction)
        try modelContext.save()
    }

    static func createTransfer(
        fromAccount: Account,
        toAccount: Account,
        fromCurrency: CurrencyCode,
        toCurrency: CurrencyCode,
        amountFromMinor: Int64,
        amountToMinor: Int64?,
        date: Date = .now,
        note: String? = nil,
        in modelContext: ModelContext
    ) throws {
        try validateAmount(amountFromMinor)
        try validateAccountCurrency(account: fromAccount, currency: fromCurrency)
        try validateAccountCurrency(account: toAccount, currency: toCurrency)

        guard fromAccount.id != toAccount.id else {
            throw TransactionServiceError.sameTransferAccounts
        }

        let resolvedAmountToMinor: Int64
        if fromCurrency == toCurrency {
            resolvedAmountToMinor = amountFromMinor
        } else {
            let incoming = amountToMinor ?? 0
            try validateAmount(incoming)
            resolvedAmountToMinor = incoming
        }

        let transferGroupId = UUID()
        let outflow = Transaction(
            kind: .expense,
            amountMinor: amountFromMinor,
            currency: fromCurrency,
            date: date,
            note: note,
            transferGroupId: transferGroupId,
            account: fromAccount,
            category: nil
        )
        let inflow = Transaction(
            kind: .income,
            amountMinor: resolvedAmountToMinor,
            currency: toCurrency,
            date: date,
            note: note,
            transferGroupId: transferGroupId,
            account: toAccount,
            category: nil
        )

        modelContext.insert(outflow)
        modelContext.insert(inflow)
        try modelContext.save()
    }

    static func validateTransaction(_ transaction: Transaction) throws {
        try validateAmount(transaction.amountMinor)
        guard transaction.account.supports(currency: transaction.currency) else {
            throw TransactionServiceError.currencyNotEnabledForAccount
        }
    }

    private static func validateAmount(_ amount: Int64) throws {
        guard amount > 0 else {
            throw TransactionServiceError.invalidAmount
        }
    }

    private static func validateAccountCurrency(account: Account, currency: CurrencyCode) throws {
        guard account.supports(currency: currency) else {
            throw TransactionServiceError.currencyNotEnabledForAccount
        }
    }
}
