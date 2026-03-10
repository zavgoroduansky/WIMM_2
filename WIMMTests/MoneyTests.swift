import Foundation
import Testing
@testable import WIMM

struct MoneyTests {
    @Test
    func minorFromInputTrimsAndAcceptsComma() {
        #expect(Money.minor(fromInput: " 10,5 ") == 1050)
        #expect(Money.minor(fromInput: "0") == Int64(0))
        #expect(Money.minor(fromInput: "") == nil)
    }

    @Test
    func minorFromDecimalRoundsToNearestMinor() {
        let decimal = Decimal(string: "1.005") ?? 0
        #expect(Money.minor(fromDecimal: decimal) == 101)
    }

    @Test
    func formatAddsCurrencySymbol() {
        let text = Money.format(minor: 1500, currency: .eur)
        #expect(text.hasPrefix("€"))
        #expect(text.contains("15.00"))
    }
}
