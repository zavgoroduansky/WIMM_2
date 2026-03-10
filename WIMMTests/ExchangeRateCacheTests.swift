import Foundation
import Testing
@testable import WIMM

@MainActor
struct ExchangeRateCacheTests {

    @Test
    func storesAndReadsRateByKey() async {
        let suiteName = "ExchangeRateCacheTests.storesAndReadsRateByKey"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let cache = ExchangeRateCache(defaults: defaults)
        let rate = Decimal(string: "1.234") ?? 0
        await cache.set(rate, for: "eur_usd_2026-01-01")

        let fetched = await cache.get(for: "eur_usd_2026-01-01")

        #expect(fetched == rate)
    }

    @Test
    func returnsNilForMissingKey() async {
        let suiteName = "ExchangeRateCacheTests.returnsNilForMissingKey"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let cache = ExchangeRateCache(defaults: defaults)
        let fetched = await cache.get(for: "missing")

        #expect(fetched == nil)
    }

    @Test
    func expiresEntriesPastTtl() async {
        let suiteName = "ExchangeRateCacheTests.expiresEntriesPastTtl"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let cache = ExchangeRateCache(defaults: defaults, ttl: -1)
        await cache.set(Decimal(2), for: "eur_usd_2026-01-01")

        let fetched = await cache.get(for: "eur_usd_2026-01-01")

        #expect(fetched == nil)
    }
}
