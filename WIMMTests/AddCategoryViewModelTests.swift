import Testing
@testable import WIMM

@MainActor
struct AddCategoryViewModelTests {
    @Test
    func saveRequiresNonEmptyName() {
        let repo = MockFinanceRepository()
        let vm = AddCategoryViewModel()

        #expect(!vm.save(using: repo))

        vm.name = "Food"
        #expect(vm.save(using: repo))
    }

    @Test
    func savePersistsKindAndColor() {
        let repo = MockFinanceRepository()
        let vm = AddCategoryViewModel()
        vm.name = "Salary"
        vm.kind = .income
        vm.colorHex = "#123456"

        let success = vm.save(using: repo)

        #expect(success)
        #expect(repo.categories.first?.name == "Salary")
        #expect(repo.categories.first?.kind == .income)
        #expect(repo.categories.first?.colorHex == "#123456")
    }
}
