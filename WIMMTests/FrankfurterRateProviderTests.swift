import Foundation
import Testing
@testable import WIMM

@MainActor
struct FrankfurterRateProviderTests {
    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    @Test
    func rateReturnsOneWhenCurrenciesMatch() async throws {
        let provider = FrankfurterRateProvider(session: makeSession())
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

        let provider = FrankfurterRateProvider(session: makeSession())

        do {
            _ = try await provider.rate(from: .eur, to: .usd, on: nil)
            #expect(false)
        } catch {
            #expect(error is ExchangeRateError)
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

        let provider = FrankfurterRateProvider(session: makeSession())

        do {
            _ = try await provider.rate(from: .eur, to: .usd, on: nil)
            #expect(false)
        } catch {
            #expect(error is ExchangeRateError)
        }
        MockURLProtocol.requestHandler = nil
    }
}
