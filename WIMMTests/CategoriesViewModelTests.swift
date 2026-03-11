import Foundation
import Testing
@testable import WIMM

@MainActor
struct CategoriesViewModelTests {
    @Test
    func keepsOnlyExpenseCategories() {
        let expense = TestDataFactory.makeCategory(name: "Food", kind: .expense)
        let income = TestDataFactory.makeCategory(name: "Salary", kind: .income)

        let vm = CategoriesViewModel(repository: MockFinanceRepository())

        #expect(vm.expenseCategories(from: [expense, income]).map(\.name) == ["Food"])
    }

    @Test
    func monthExpenseSummarizesByCurrency() {
        let group = TestDataFactory.makeAccountGroup()
        let account = TestDataFactory.makeAccount(accountGroup: group)
        let category = TestDataFactory.makeCategory(name: "Food", kind: .expense)

        category.transactions = [
            Transaction(kind: .expense, amountMinor: 1000, currency: .eur, date: .now, account: account, category: category),
            Transaction(kind: .expense, amountMinor: 500, currency: .eur, date: .now, account: account, category: category)
        ]

        let vm = CategoriesViewModel(repository: MockFinanceRepository())
        let text = vm.expenseForCurrentMonth(category)

        #expect(text.contains("€15.00"))
    }

    @Test
    func expenseCategoriesSortByMonthlyExpenseDescending() {
        let now = Date()
        let group = TestDataFactory.makeAccountGroup()
        let account = TestDataFactory.makeAccount(accountGroup: group)
        group.accounts = [account]

        let high = TestDataFactory.makeCategory(name: "High", kind: .expense)
        let low = TestDataFactory.makeCategory(name: "Low", kind: .expense)

        let highTx = Transaction(
            kind: .expense,
            amountMinor: 2_000,
            currency: .eur,
            date: now,
            account: account,
            category: high
        )
        let lowTx = Transaction(
            kind: .expense,
            amountMinor: 500,
            currency: .eur,
            date: now,
            account: account,
            category: low
        )

        high.transactions = [highTx]
        low.transactions = [lowTx]

        let vm = CategoriesViewModel(repository: MockFinanceRepository())
        let sorted = vm.expenseCategories(from: [low, high])

        #expect(sorted.first?.name == "High")
        #expect(vm.totalExpenseMinor(for: high, now: now) == 2_000)
        #expect(vm.totalExpenseMinor(for: low, now: now) == 500)
    }

    @Test
    func tapCategoryOpensTransactionWithPreselectedCategory() {
        let category = TestDataFactory.makeCategory(name: "Food", kind: .expense)
        let vm = CategoriesViewModel(repository: MockFinanceRepository())

        vm.didTapCategory(category)

        #expect(vm.showNewTransaction)
        #expect(vm.preselectedCategoryID == category.id)
    }

    @Test
    func tapNewClearsPreselectedCategory() {
        let vm = CategoriesViewModel(repository: MockFinanceRepository())
        vm.preselectedCategoryID = UUID()

        vm.didTapNew()

        #expect(vm.showNewTransaction)
        #expect(vm.preselectedCategoryID == nil)
    }
}
