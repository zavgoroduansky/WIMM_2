import Foundation

protocol ExchangeRateProvider {
    func rate(from: CurrencyCode, to: CurrencyCode, on date: Date?) async throws -> Decimal
}

enum ExchangeRateError: LocalizedError {
    case invalidResponse
    case missingRate(CurrencyCode, CurrencyCode)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Exchange service returned an invalid response."
        case let .missingRate(from, to):
            return "Missing exchange rate from \(from.rawValue.uppercased()) to \(to.rawValue.uppercased())."
        }
    }
}

actor ExchangeRateCache {
    struct Entry: Codable {
        let rateString: String
        let savedAt: Date
    }

    private let key = "exchange_rate_cache_v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func get(for cacheKey: String) -> Decimal? {
        guard let data = defaults.data(forKey: key),
              let map = try? JSONDecoder().decode([String: Entry].self, from: data),
              let entry = map[cacheKey] else {
            return nil
        }
        return Decimal(string: entry.rateString)
    }

    func set(_ rate: Decimal, for cacheKey: String) {
        var map: [String: Entry] = [:]
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([String: Entry].self, from: data) {
            map = decoded
        }
        map[cacheKey] = Entry(rateString: NSDecimalNumber(decimal: rate).stringValue, savedAt: .now)
        if let encoded = try? JSONEncoder().encode(map) {
            defaults.set(encoded, forKey: key)
        }
    }
}

struct FrankfurterRateProvider: ExchangeRateProvider {
    private struct Response: Codable {
        let rates: [String: Double]
    }

    private let session: URLSession
    private let cache: ExchangeRateCache
    private let calendar: Calendar

    init(
        session: URLSession = .shared,
        cache: ExchangeRateCache = ExchangeRateCache(),
        calendar: Calendar = .current
    ) {
        self.session = session
        self.cache = cache
        self.calendar = calendar
    }

    func rate(from: CurrencyCode, to: CurrencyCode, on date: Date? = nil) async throws -> Decimal {
        if from == to {
            return 1
        }

        let cacheKey = makeCacheKey(from: from, to: to, date: date)
        if let cached = await cache.get(for: cacheKey) {
            return cached
        }

        let requestURL = try makeURL(from: from, to: to, on: date)
        let (data, response) = try await session.data(from: requestURL)
        guard let httpResponse = response as? HTTPURLResponse, 200 ..< 300 ~= httpResponse.statusCode else {
            throw ExchangeRateError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard let raw = decoded.rates[to.rawValue.uppercased()] else {
            throw ExchangeRateError.missingRate(from, to)
        }

        let rate = Decimal(raw)
        await cache.set(rate, for: cacheKey)
        return rate
    }

    func convert(
        minor amountMinor: Int64,
        from: CurrencyCode,
        to: CurrencyCode,
        date: Date? = nil
    ) async throws -> Int64 {
        let fxRate = try await rate(from: from, to: to, on: date)
        let sourceAmount = Money.decimal(fromMinor: amountMinor)
        let converted = sourceAmount * fxRate
        return Money.minor(fromDecimal: converted)
    }

    private func makeURL(from: CurrencyCode, to: CurrencyCode, on date: Date?) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.frankfurter.dev"

        if let date {
            let formattedDate = Self.isoDateFormatter.string(from: date)
            components.path = "/v1/\(formattedDate)"
        } else {
            components.path = "/v1/latest"
        }

        components.queryItems = [
            URLQueryItem(name: "base", value: from.rawValue.uppercased()),
            URLQueryItem(name: "symbols", value: to.rawValue.uppercased())
        ]

        guard let url = components.url else {
            throw ExchangeRateError.invalidResponse
        }
        return url
    }

    private func makeCacheKey(from: CurrencyCode, to: CurrencyCode, date: Date?) -> String {
        let datePart: String
        if let date {
            datePart = Self.isoDateFormatter.string(from: date)
        } else {
            datePart = Self.isoDateFormatter.string(from: calendar.startOfDay(for: .now))
        }

        return "\(from.rawValue)_\(to.rawValue)_\(datePart)"
    }

    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct AccountGroupBalanceSummary {
    let currency: CurrencyCode
    let totalMinor: Int64
    let missingAccounts: [Account]
}

@MainActor
protocol AccountGroupBalanceServicing {
    func total(
        for accountGroup: AccountGroup,
        in defaultCurrency: CurrencyCode,
        date: Date?
    ) async -> AccountGroupBalanceSummary
}

@MainActor
final class AccountGroupBalanceService: AccountGroupBalanceServicing {
    private let rateProvider: ExchangeRateProvider

    init(rateProvider: ExchangeRateProvider) {
        self.rateProvider = rateProvider
    }

    func total(
        for accountGroup: AccountGroup,
        in defaultCurrency: CurrencyCode,
        date: Date? = nil
    ) async -> AccountGroupBalanceSummary {
        var total: Int64 = 0
        var missing: [Account] = []

        for account in accountGroup.accounts {
            for currency in account.enabledCurrencies {
                do {
                    let converted = try await convert(
                        amountMinor: account.currentBalanceMinor(for: currency),
                        from: currency,
                        to: defaultCurrency,
                        date: date
                    )
                    total += converted
                } catch {
                    if !missing.contains(where: { $0.id == account.id }) {
                        missing.append(account)
                    }
                }
            }
        }

        return AccountGroupBalanceSummary(currency: defaultCurrency, totalMinor: total, missingAccounts: missing)
    }

    private func convert(
        amountMinor: Int64,
        from: CurrencyCode,
        to defaultCurrency: CurrencyCode,
        date: Date?
    ) async throws -> Int64 {
        if from == defaultCurrency {
            return amountMinor
        }

        if let frankfurter = rateProvider as? FrankfurterRateProvider {
            return try await frankfurter.convert(
                minor: amountMinor,
                from: from,
                to: defaultCurrency,
                date: date
            )
        }

        let rate = try await rateProvider.rate(from: from, to: defaultCurrency, on: date)
        let converted = Money.decimal(fromMinor: amountMinor) * rate
        return Money.minor(fromDecimal: converted)
    }
}
