import Testing
@testable import WIMM

@MainActor
struct NewTransactionViewModelTests {

    @Test
    func filtersCategoriesByTransactionKind() {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let account = TestDataFactory.makeAccount(name: "Wallet", accountGroup: group)
        group.accounts = [account]

        let incomeCategory = TestDataFactory.makeCategory(name: "Salary", kind: .income)
        let expenseCategory = TestDataFactory.makeCategory(name: "Food", kind: .expense)

        let viewModel = NewTransactionViewModel(defaultMode: .expense, transactionService: MockTransactionService())
        viewModel.updateData(
            accountGroups: [group],
            categories: [incomeCategory, expenseCategory],
            defaultCurrency: .eur
        )

        #expect(viewModel.filteredCategories.map(\.name) == ["Food"])

        viewModel.mode = .income
        viewModel.handleModeChange()

        #expect(viewModel.filteredCategories.map(\.name) == ["Salary"])
    }

    @Test
    func saveIncomeUsesInjectedService() throws {
        let context = try TestDataFactory.makeInMemoryContext()

        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let account = TestDataFactory.makeAccount(name: "Wallet", accountGroup: group)
        group.accounts = [account]

        let category = TestDataFactory.makeCategory(name: "Salary", kind: .income)

        let service = MockTransactionService()
        let viewModel = NewTransactionViewModel(defaultMode: .income, transactionService: service)

        viewModel.updateData(accountGroups: [group], categories: [category], defaultCurrency: .eur)
        viewModel.mode = .income
        viewModel.handleModeChange()
        viewModel.amount = "100"
        viewModel.note = "  test note  "

        let isSaved = viewModel.save(in: context)

        #expect(isSaved)
        #expect(service.incomeCalls == 1)
        #expect(service.lastIncomeAmountMinor == 10_000)
        #expect(service.lastIncomeCurrency == .eur)
        #expect(service.lastIncomeCategoryID == category.id)
        #expect(service.lastIncomeNote == "test note")
    }
}
