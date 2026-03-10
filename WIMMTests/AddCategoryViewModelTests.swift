import Testing
@testable import WIMM

@MainActor
struct AddCategoryViewModelTests {
    @Test
    func saveRequiresNonEmptyName() {
        let repo = MockFinanceRepository()
        let vm = AddCategoryViewModel(repository: repo)

        #expect(!vm.save())

        vm.name = "Food"
        #expect(vm.save())
    }

    @Test
    func savePersistsKindAndColor() {
        let repo = MockFinanceRepository()
        let vm = AddCategoryViewModel(repository: repo)
        vm.name = "Salary"
        vm.kind = .income
        vm.colorHex = "#123456"

        let success = vm.save()

        #expect(success)
        #expect(repo.categories.first?.name == "Salary")
        #expect(repo.categories.first?.kind == .income)
        #expect(repo.categories.first?.colorHex == "#123456")
    }
}
