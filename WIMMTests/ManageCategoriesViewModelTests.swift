import Testing
@testable import WIMM

@MainActor
struct ManageCategoriesViewModelTests {
    @Test
    func sortsByKindThenName() {
        let income = TestDataFactory.makeCategory(name: "B", kind: .income)
        let expenseA = TestDataFactory.makeCategory(name: "A", kind: .expense)
        let expenseB = TestDataFactory.makeCategory(name: "B", kind: .expense)

        let vm = ManageCategoriesViewModel()
        vm.update(categories: [income, expenseB, expenseA])

        #expect(vm.sortedCategories.map(\.name) == ["A", "B", "B"])
        #expect(vm.sortedCategories.first?.kind == .expense)
    }
}
