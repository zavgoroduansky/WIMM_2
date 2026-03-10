import Testing
@testable import WIMM

@MainActor
struct ManageCategoriesViewModelTests {
    @Test
    func filtersByKindAndSortsByName() {
        let income = TestDataFactory.makeCategory(name: "B", kind: .income)
        let expenseA = TestDataFactory.makeCategory(name: "A", kind: .expense)
        let expenseB = TestDataFactory.makeCategory(name: "B", kind: .expense)

        let vm = ManageCategoriesViewModel()
        let sorted = vm.sortedCategories(from: [income, expenseB, expenseA], kind: .expense)

        #expect(sorted.map(\.name) == ["A", "B"])
        #expect(sorted.allSatisfy { $0.kind == .expense })
    }

    @Test
    func canDeleteCategoryIsFalseWhenTransactionsExist() {
        let group = TestDataFactory.makeAccountGroup()
        let account = TestDataFactory.makeAccount(accountGroup: group)
        let category = TestDataFactory.makeCategory(name: "Food", kind: .expense)
        let tx = Transaction(kind: .expense, amountMinor: 1000, currency: .eur, account: account, category: category)

        let repo = MockFinanceRepository()
        repo.seed(groups: [group], categories: [category], transactions: [tx])

        let vm = ManageCategoriesViewModel()
        vm.load(using: repo)

        #expect(!vm.canDeleteCategory(category))
        #expect(vm.deleteCategoryBlockedReason(category) != nil)
    }

    @Test
    func updateCategoryDoesNotChangeKindWhenTransactionsExist() {
        let group = TestDataFactory.makeAccountGroup()
        let account = TestDataFactory.makeAccount(accountGroup: group)
        let category = TestDataFactory.makeCategory(name: "Food", kind: .expense)
        let tx = Transaction(kind: .expense, amountMinor: 1000, currency: .eur, account: account, category: category)

        let repo = MockFinanceRepository()
        repo.seed(groups: [group], categories: [category], transactions: [tx])

        let vm = ManageCategoriesViewModel()
        vm.load(using: repo)

        vm.updateCategory(
            category,
            name: "New Food",
            kind: .income,
            colorHex: "#FFFFFF",
            using: repo
        )

        #expect(category.name == "New Food")
        #expect(category.colorHex == "#FFFFFF")
        #expect(category.kind == .expense)
    }
}
