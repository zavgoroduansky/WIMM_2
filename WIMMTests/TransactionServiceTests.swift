import Foundation
import SwiftData
import Testing
@testable import WIMM

struct TransactionServiceTests {
    @Test
    func createIncomePersistsTransaction() throws {
        let context = try TestDataFactory.makeInMemoryContext()
        let group = TestDataFactory.makeAccountGroup()
        let account = TestDataFactory.makeAccount(accountGroup: group)
        context.insert(group)
        context.insert(account)

        let service = TransactionService()
        try service.createIncome(
            amountMinor: 1000,
            account: account,
            currency: .eur,
            category: nil,
            date: Date(timeIntervalSince1970: 0),
            note: "note",
            in: context
        )

        let descriptor = FetchDescriptor<Transaction>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched.first?.kind == .income)
    }

    @Test
    func createTransferRequiresDifferentAccounts() throws {
        let context = try TestDataFactory.makeInMemoryContext()
        let group = TestDataFactory.makeAccountGroup()
        let account = TestDataFactory.makeAccount(accountGroup: group)
        context.insert(group)
        context.insert(account)

        let service = TransactionService()
        var caught: TransactionServiceError?
        do {
            try service.createTransfer(
                fromAccount: account,
                toAccount: account,
                fromCurrency: .eur,
                toCurrency: .eur,
                amountFromMinor: 1000,
                amountToMinor: nil,
                date: .now,
                note: nil,
                in: context
            )
        } catch let error as TransactionServiceError {
            caught = error
        }

        #expect(caught == .sameTransferAccounts)
    }

    @Test
    func createTransferUsesAmountToWhenCurrenciesDiffer() throws {
        let context = try TestDataFactory.makeInMemoryContext()
        let group = TestDataFactory.makeAccountGroup()
        let from = TestDataFactory.makeAccount(enabledCurrencies: [.eur], accountGroup: group)
        let to = TestDataFactory.makeAccount(enabledCurrencies: [.usd], accountGroup: group)
        context.insert(group)
        context.insert(from)
        context.insert(to)

        let service = TransactionService()
        try service.createTransfer(
            fromAccount: from,
            toAccount: to,
            fromCurrency: .eur,
            toCurrency: .usd,
            amountFromMinor: 1000,
            amountToMinor: 2500,
            date: .now,
            note: nil,
            in: context
        )

        let fetched = try context.fetch(FetchDescriptor<Transaction>())
        let income = fetched.first { $0.kind == .income }
        let expense = fetched.first { $0.kind == .expense }
        #expect(fetched.count == 2)
        #expect(expense?.amountMinor == 1000)
        #expect(income?.amountMinor == 2500)
    }

    @Test
    func createTransferUsesAmountFromWhenCurrenciesSame() throws {
        let context = try TestDataFactory.makeInMemoryContext()
        let group = TestDataFactory.makeAccountGroup()
        let from = TestDataFactory.makeAccount(enabledCurrencies: [.eur], accountGroup: group)
        let to = TestDataFactory.makeAccount(enabledCurrencies: [.eur], accountGroup: group)
        context.insert(group)
        context.insert(from)
        context.insert(to)

        let service = TransactionService()
        try service.createTransfer(
            fromAccount: from,
            toAccount: to,
            fromCurrency: .eur,
            toCurrency: .eur,
            amountFromMinor: 1000,
            amountToMinor: 9999,
            date: .now,
            note: nil,
            in: context
        )

        let fetched = try context.fetch(FetchDescriptor<Transaction>())
        let income = fetched.first { $0.kind == .income }
        #expect(income?.amountMinor == 1000)
    }

    @Test
    func validateTransactionRejectsUnsupportedCurrency() throws {
        let group = TestDataFactory.makeAccountGroup()
        let account = TestDataFactory.makeAccount(primaryCurrency: .eur, enabledCurrencies: [.eur], accountGroup: group)
        let transaction = Transaction(kind: .income, amountMinor: 1000, currency: .usd, account: account)

        let service = TransactionService()
        var caught: TransactionServiceError?
        do {
            try service.validateTransaction(transaction)
        } catch let error as TransactionServiceError {
            caught = error
        }

        #expect(caught == .currencyNotEnabledForAccount)
    }
}
