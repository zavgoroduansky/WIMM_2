import Foundation

protocol AccountEnabledCurrenciesCoding {
    func decode(raw: String, primaryCurrency: CurrencyCode) -> [CurrencyCode]
    func encode(currencies: [CurrencyCode], primaryCurrency: CurrencyCode) -> String
}

final class AccountEnabledCurrenciesCodec: AccountEnabledCurrenciesCoding {
    func decode(raw: String, primaryCurrency: CurrencyCode) -> [CurrencyCode] {
        let parsed = raw
            .split(separator: ",")
            .compactMap { CurrencyCode(rawValue: String($0)) }

        if parsed.isEmpty {
            return [primaryCurrency]
        }
        if parsed.contains(primaryCurrency) {
            return parsed
        }
        return [primaryCurrency] + parsed
    }

    func encode(currencies: [CurrencyCode], primaryCurrency: CurrencyCode) -> String {
        var values: [CurrencyCode] = []
        for currency in CurrencyCode.allCases where currencies.contains(currency) {
            values.append(currency)
        }
        if !values.contains(primaryCurrency) {
            values.insert(primaryCurrency, at: 0)
        }
        return values.map(\.rawValue).joined(separator: ",")
    }
}
