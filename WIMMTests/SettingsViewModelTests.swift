import Testing
@testable import WIMM

@MainActor
struct SettingsViewModelTests {
    @Test
    func parsesDefaultCurrencyWithFallback() {
        let vm = SettingsViewModel()

        #expect(vm.defaultCurrency(from: "usd") == .usd)
        #expect(vm.defaultCurrency(from: "unknown") == .eur)
    }

    @Test
    func allCurrenciesReturnsAllCases() {
        let vm = SettingsViewModel()
        #expect(vm.allCurrencies.contains(.eur))
        #expect(vm.allCurrencies.contains(.usd))
        #expect(vm.allCurrencies.contains(.uah))
    }
}
