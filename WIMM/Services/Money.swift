import Foundation

enum Money {
    static let minorUnitFactor = Decimal(100)
    private static var formatterCache: [CurrencyCode: NumberFormatter] = [:]
    private static let formatterLock = NSLock()

    static func decimal(fromMinor minor: Int64) -> Decimal {
        Decimal(minor) / minorUnitFactor
    }

    static func minor(fromDecimal value: Decimal) -> Int64 {
        var multiplied = value * minorUnitFactor
        var rounded = Decimal()
        NSDecimalRound(&rounded, &multiplied, 0, .plain)
        return NSDecimalNumber(decimal: rounded).int64Value
    }

    static func format(minor: Int64, currency: CurrencyCode) -> String {
        let decimalValue = decimal(fromMinor: minor)
        let formatter = formatter(for: currency)

        let number = formatter.string(from: NSDecimalNumber(decimal: decimalValue)) ?? "\(decimalValue)"
        return "\(currency.symbol)\(number)"
    }

    static func minor(fromInput input: String) -> Int64? {
        let normalized = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard !normalized.isEmpty, let decimal = Decimal(string: normalized) else {
            return nil
        }
        return minor(fromDecimal: decimal)
    }

    private static func formatter(for currency: CurrencyCode) -> NumberFormatter {
        formatterLock.lock()
        defer { formatterLock.unlock() }

        if let cached = formatterCache[currency] {
            return cached
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: currency.localeIdentifier)
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatterCache[currency] = formatter
        return formatter
    }
}
