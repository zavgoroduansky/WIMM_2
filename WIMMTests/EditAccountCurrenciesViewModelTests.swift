import Testing
@testable import WIMM

@MainActor
struct EditAccountCurrenciesViewModelTests {
    @Test
    func applyInitialStateEnsuresPrimaryIsEnabled() {
        let group = TestDataFactory.makeAccountGroup()
        let account = TestDataFactory.makeAccount(
            primaryCurrency: .usd,
            enabledCurrencies: [.eur],
            accountGroup: group
        )

        let vm = EditAccountCurrenciesViewModel()
        vm.applyInitialState(from: account)

        #expect(vm.selected.contains(.usd))
        #expect(vm.primary == .usd)
    }
}
