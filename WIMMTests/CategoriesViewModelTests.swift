import Foundation
import Testing
@testable import WIMM

@MainActor
struct CategoriesViewModelTests {
    @Test
    func keepsOnlyExpenseCategories() {
        let expense = TestDataFactory.makeCategory(name: "Food", kind: .expense)
        let income = TestDataFactory.makeCategory(name: "Salary", kind: .income)

        let vm = CategoriesViewModel()
        vm.update(categories: [expense, income])

        #expect(vm.expenseCategories.map(\.name) == ["Food"])
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

        let vm = CategoriesViewModel()
        let text = vm.expenseForCurrentMonth(category)

        #expect(text.contains("€15.00"))
    }
}
