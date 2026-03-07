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
}
