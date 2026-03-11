import Foundation
import Testing
@testable import WIMM

@MainActor
struct NewTransactionUseCaseTests {
    @Test
    func loadDataReturnsGroupsAndCategories() {
        let group = TestDataFactory.makeAccountGroup(name: "Main")
        let category = TestDataFactory.makeCategory(name: "Food", kind: .expense)
        let repo = MockFinanceRepository()
        repo.seed(groups: [group], categories: [category], transactions: [])

        let useCase = NewTransactionUseCase(repository: repo)
        let result = useCase.loadData()

        #expect(result.groups.map(\.name) == ["Main"])
        #expect(result.categories.map(\.name) == ["Food"])
    }

    @Test
    func saveIncomeTrimsNoteAndCallsRepository() throws {
        let group = TestDataFactory.makeAccountGroup(name: "Main")
        let account = TestDataFactory.makeAccount(accountGroup: group)
        let category = TestDataFactory.makeCategory(name: "Salary", kind: .income)
        let repo = MockFinanceRepository()

        let input = NewTransactionUseCase.Input(
            mode: .income,
            amount: "100",
            amountTo: "",
            selectedAccount: account,
            selectedCategory: category,
            fromAccount: nil,
            toAccount: nil,
            transactionCurrency: .eur,
            transferFromCurrency: .eur,
            transferToCurrency: .eur,
            date: Date(timeIntervalSince1970: 0),
            note: "  test  ",
            usesManualAmountTo: false
        )

        let useCase = NewTransactionUseCase(repository: repo)
        try useCase.save(input: input)

        #expect(repo.createIncomeCalls == 1)
        #expect(repo.lastIncomeAmountMinor == 10_000)
        #expect(repo.lastIncomeCategoryID == category.id)
        #expect(repo.lastIncomeNote == "test")
    }

    @Test
    func saveIncomeRejectsInvalidAmount() {
        let group = TestDataFactory.makeAccountGroup(name: "Main")
        let account = TestDataFactory.makeAccount(accountGroup: group)
        let repo = MockFinanceRepository()

        let input = NewTransactionUseCase.Input(
            mode: .income,
            amount: "0",
            amountTo: "",
            selectedAccount: account,
            selectedCategory: nil,
            fromAccount: nil,
            toAccount: nil,
            transactionCurrency: .eur,
            transferFromCurrency: .eur,
            transferToCurrency: .eur,
            date: Date(),
            note: "",
            usesManualAmountTo: false
        )

        let useCase = NewTransactionUseCase(repository: repo)
        var caught: TransactionServiceError?
        do {
            try useCase.save(input: input)
        } catch let error as TransactionServiceError {
            caught = error
        } catch {
            #expect(false, "Unexpected error: \(error)")
        }

        #expect(caught == .invalidAmount)
    }

    @Test
    func transferDifferentCurrencyRequiresAmountToWhenManual() {
        let group = TestDataFactory.makeAccountGroup(name: "Main")
        let from = TestDataFactory.makeAccount(accountGroup: group)
        let to = TestDataFactory.makeAccount(accountGroup: group)
        let repo = MockFinanceRepository()

        let input = NewTransactionUseCase.Input(
            mode: .transfer,
            amount: "10",
            amountTo: "",
            selectedAccount: nil,
            selectedCategory: nil,
            fromAccount: from,
            toAccount: to,
            transactionCurrency: .eur,
            transferFromCurrency: .eur,
            transferToCurrency: .usd,
            date: Date(),
            note: "",
            usesManualAmountTo: true
        )

        let useCase = NewTransactionUseCase(repository: repo)
        var caught: TransactionServiceError?
        do {
            try useCase.save(input: input)
        } catch let error as TransactionServiceError {
            caught = error
        } catch {
            #expect(false, "Unexpected error: \(error)")
        }

        #expect(caught == .invalidAmount)
    }

    @Test
    func transferSameCurrencyIgnoresAmountTo() throws {
        let group = TestDataFactory.makeAccountGroup(name: "Main")
        let from = TestDataFactory.makeAccount(accountGroup: group)
        let to = TestDataFactory.makeAccount(accountGroup: group)
        let repo = MockFinanceRepository()

        let input = NewTransactionUseCase.Input(
            mode: .transfer,
            amount: "10",
            amountTo: "999",
            selectedAccount: nil,
            selectedCategory: nil,
            fromAccount: from,
            toAccount: to,
            transactionCurrency: .eur,
            transferFromCurrency: .eur,
            transferToCurrency: .eur,
            date: Date(timeIntervalSince1970: 0),
            note: "",
            usesManualAmountTo: false
        )

        let useCase = NewTransactionUseCase(repository: repo)
        try useCase.save(input: input)

        #expect(repo.createTransferCalls == 1)
        #expect(repo.lastTransferFromAmountMinor == 1_000)
        #expect(repo.lastTransferToAmountMinor == 1_000)
    }
}
