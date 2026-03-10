import Testing
@testable import WIMM

@MainActor
struct AddAccountViewModelTests {
    @Test
    func canSaveRequiresNameAndGroupAndCurrency() {
        let group = TestDataFactory.makeAccountGroup(name: "Main")
        let vm = AddAccountViewModel(repository: MockFinanceRepository())
        vm.update(accountGroups: [group], defaultCurrencyRaw: CurrencyCode.eur.rawValue)

        #expect(!vm.canSave)

        vm.name = "Wallet"
        vm.selectedAccountGroupID = group.id

        #expect(vm.canSave)
    }

    @Test
    func saveCreatesAccountInSelectedGroup() throws {
        let context = try TestDataFactory.makeInMemoryContext()
        let repository = SwiftDataFinanceRepository(modelContext: context)
        let group = TestDataFactory.makeAccountGroup(name: "Main")

        let vm = AddAccountViewModel(repository: repository)
        vm.update(accountGroups: [group], defaultCurrencyRaw: CurrencyCode.eur.rawValue)
        vm.name = "Wallet"
        vm.selectedAccountGroupID = group.id

        let success = vm.save()

        #expect(success)
        #expect(group.accounts.contains(where: { $0.name == "Wallet" }))
    }

    @Test
    func saveCreatesNewGroupWhenRequested() {
        let repo = MockFinanceRepository()
        let vm = AddAccountViewModel(repository: repo)
        vm.update(accountGroups: [], defaultCurrencyRaw: CurrencyCode.eur.rawValue)

        vm.groupMode = .new
        vm.newGroupName = "Cash"
        vm.name = "Wallet"

        let success = vm.save()

        #expect(success)
        #expect(repo.accountGroups.contains(where: { $0.name == "Cash" }))
        let createdGroup = repo.accountGroups.first { $0.name == "Cash" }
        #expect(createdGroup?.accounts.contains(where: { $0.name == "Wallet" }) == true)
    }

    @Test
    func toggleCurrencyMovesPrimaryWhenRemoved() {
        let vm = AddAccountViewModel(repository: MockFinanceRepository())
        vm.selectedCurrencies = [.eur, .usd]
        vm.primaryCurrency = .eur

        vm.toggleCurrency(.eur, isOn: false)

        #expect(vm.selectedCurrencies.contains(.usd))
        #expect(vm.primaryCurrency == .usd)
    }
}
