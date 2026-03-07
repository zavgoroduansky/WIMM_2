import Foundation
import SwiftData
@testable import WIMM

final class MockTransactionService: TransactionServicing {
    var incomeCalls = 0
    var expenseCalls = 0
    var transferCalls = 0

    var lastIncomeAmountMinor: Int64?
    var lastIncomeCurrency: CurrencyCode?
    var lastIncomeCategoryID: UUID?
    var lastIncomeNote: String?

    func createIncome(
        amountMinor: Int64,
        account: Account,
        currency: CurrencyCode,
        category: WIMM.Category?,
        date: Date,
        note: String?,
        in modelContext: ModelContext
    ) throws {
        incomeCalls += 1
        lastIncomeAmountMinor = amountMinor
        lastIncomeCurrency = currency
        lastIncomeCategoryID = category?.id
        lastIncomeNote = note
    }

    func createExpense(
        amountMinor: Int64,
        account: Account,
        currency: CurrencyCode,
        category: WIMM.Category?,
        date: Date,
        note: String?,
        in modelContext: ModelContext
    ) throws {
        expenseCalls += 1
    }

    func createTransfer(
        fromAccount: Account,
        toAccount: Account,
        fromCurrency: CurrencyCode,
        toCurrency: CurrencyCode,
        amountFromMinor: Int64,
        amountToMinor: Int64?,
        date: Date,
        note: String?,
        in modelContext: ModelContext
    ) throws {
        transferCalls += 1
    }

    func validateTransaction(_ transaction: Transaction) throws {}
}

struct MockRateProvider: ExchangeRateProvider {
    let rates: [String: Decimal]

    init(rates: [String: Decimal] = [:]) {
        self.rates = rates
    }

    func rate(from: CurrencyCode, to: CurrencyCode, on date: Date?) async throws -> Decimal {
        if from == to {
            return 1
        }

        let key = "\(from.rawValue)_\(to.rawValue)"
        if let rate = rates[key] {
            return rate
        }

        throw ExchangeRateError.missingRate(from, to)
    }
}
