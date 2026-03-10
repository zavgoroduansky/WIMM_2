import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    func defaultCurrency(from rawValue: String) -> CurrencyCode {
        CurrencyCode(rawValue: rawValue) ?? .eur
    }

    var allCurrencies: [CurrencyCode] {
        CurrencyCode.allCases
    }
}
