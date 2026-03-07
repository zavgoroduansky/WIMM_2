import Testing
@testable import WIMM

@MainActor
struct AddCategoryViewModelTests {
    @Test
    func saveRequiresNonEmptyName() throws {
        let context = try TestDataFactory.makeInMemoryContext()
        let vm = AddCategoryViewModel()

        #expect(!vm.save(in: context))

        vm.name = "Food"
        #expect(vm.save(in: context))
    }
}
