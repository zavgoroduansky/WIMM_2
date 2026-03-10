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

    @Test
    func saveUpdatesAccountCurrencies() {
        let group = TestDataFactory.makeAccountGroup()
        let account = TestDataFactory.makeAccount(
            primaryCurrency: .eur,
            enabledCurrencies: [.eur],
            accountGroup: group
        )

        let repo = MockFinanceRepository()
        let vm = EditAccountCurrenciesViewModel()
        vm.selected = [.usd]
        vm.primary = .usd

        vm.save(account: account, using: repo)

        #expect(account.primaryCurrency == .usd)
        #expect(account.enabledCurrencies.contains(.usd))
        #expect(repo.saveCalls == 1)
    }
}
