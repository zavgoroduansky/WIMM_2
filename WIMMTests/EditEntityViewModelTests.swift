import Testing
@testable import WIMM

@MainActor
struct EditEntityViewModelTests {
    @Test
    func renameEntityRequiresNonEmptyName() {
        let vm = RenameEntityViewModel(initialName: "Cash")
        #expect(vm.canSave)

        vm.name = "   "
        #expect(!vm.canSave)
    }

    @Test
    func editAccountViewModelMaintainsPrimaryCurrency() {
        let group = TestDataFactory.makeAccountGroup()
        let account = TestDataFactory.makeAccount(primaryCurrency: .eur, enabledCurrencies: [.eur], accountGroup: group)
        let vm = EditAccountViewModel(account: account, canEditStructure: true)

        vm.toggleCurrency(.eur, isOn: false)

        #expect(vm.selectedCurrencies.contains(.eur))
        #expect(vm.primaryCurrency == .eur)
    }

    @Test
    func editCategoryViewModelHasDefaultColor() {
        let category = TestDataFactory.makeCategory(name: "Food", kind: .expense)
        let vm = EditCategoryViewModel(category: category, canEditKind: false)

        #expect(vm.colorHex == CategoryColorPalette.defaultHex)
        #expect(!vm.canEditKind)
    }
}
