import Testing
@testable import WIMM

struct AccountEnabledCurrenciesCodecTests {
    @Test
    func decodeFallsBackToPrimary() {
        let codec = AccountEnabledCurrenciesCodec()
        let result = codec.decode(raw: "", primaryCurrency: .usd)
        #expect(result == [.usd])
    }

    @Test
    func decodePrependsPrimaryWhenMissing() {
        let codec = AccountEnabledCurrenciesCodec()
        let result = codec.decode(raw: "eur,uah", primaryCurrency: .usd)
        #expect(result.first == .usd)
        #expect(result.contains(.eur))
        #expect(result.contains(.uah))
    }

    @Test
    func encodeEnsuresPrimaryAndOrdersByAllCases() {
        let codec = AccountEnabledCurrenciesCodec()
        let encoded = codec.encode(currencies: [.uah, .usd], primaryCurrency: .eur)
        let first = String(encoded.split(separator: ",").first ?? "")
        #expect(first == "eur")
        #expect(encoded.contains("usd"))
        #expect(encoded.contains("uah"))
    }
}
