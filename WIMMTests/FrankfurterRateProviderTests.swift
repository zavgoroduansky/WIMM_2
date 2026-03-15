import Foundation
import Testing
@testable import WIMM

@Suite(.serialized)
@MainActor
struct FrankfurterRateProviderTests {
    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    @Test
    func rateReturnsOneWhenCurrenciesMatch() async throws {
        let provider = FrankfurterRateProvider(
            session: makeSession(),
            cache: ExchangeRateCache(defaults: UserDefaults(suiteName: "frankfurter-test-1") ?? .standard),
            calendar: Calendar.current
        )
        let rate = try await provider.rate(from: .eur, to: .eur, on: nil)
        #expect(rate == 1)
        MockURLProtocol.requestHandler = nil
    }

    @Test
    func rateThrowsInvalidResponseOnNon200() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        let provider = FrankfurterRateProvider(
            session: makeSession(),
            cache: ExchangeRateCache(defaults: UserDefaults(suiteName: "frankfurter-test-2") ?? .standard),
            calendar: Calendar.current
        )

        await #expect(throws: ExchangeRateError.self) {
            _ = try await provider.rate(from: .eur, to: .usd, on: nil)
        }
        MockURLProtocol.requestHandler = nil
    }

    @Test
    func rateThrowsMissingRateWhenSymbolAbsent() async {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = """
            {\"rates\": {\"GBP\": 0.8}}
            """.data(using: .utf8)!
            return (response, data)
        }

        let provider = FrankfurterRateProvider(
            session: makeSession(),
            cache: ExchangeRateCache(defaults: UserDefaults(suiteName: "frankfurter-test-3") ?? .standard),
            calendar: Calendar.current
        )

        await #expect(throws: ExchangeRateError.self) {
            _ = try await provider.rate(from: .eur, to: .usd, on: nil)
        }
        MockURLProtocol.requestHandler = nil
    }
}
