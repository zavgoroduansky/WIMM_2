import Testing
@testable import WIMM

@MainActor
struct AddAccountViewModelTests {
    @Test
    func canSaveRequiresNameAndGroupAndCurrency() {
        let group = TestDataFactory.makeAccountGroup(name: "Main")
        let vm = AddAccountViewModel()
        vm.update(accountGroups: [group], defaultCurrencyRaw: CurrencyCode.eur.rawValue)

        #expect(!vm.canSave)

        vm.name = "Wallet"
        vm.selectedAccountGroupID = group.id

        #expect(vm.canSave)
    }

    @Test
    func saveCreatesAccountInSelectedGroup() throws {
        let context = try TestDataFactory.makeInMemoryContext()
        let group = TestDataFactory.makeAccountGroup(name: "Main")

        let vm = AddAccountViewModel()
        vm.update(accountGroups: [group], defaultCurrencyRaw: CurrencyCode.eur.rawValue)
        vm.name = "Wallet"
        vm.selectedAccountGroupID = group.id

        let success = vm.save(in: context)

        #expect(success)
        #expect(group.accounts.contains(where: { $0.name == "Wallet" }))
    }
}
