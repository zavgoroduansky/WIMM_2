import Foundation
import Testing
@testable import WIMM

@MainActor
struct AccountGroupBalanceServiceTests {
    @Test
    func totalsConvertAllAccountCurrencies() async {
        let group = TestDataFactory.makeAccountGroup(name: "Main")
        let accountEur = TestDataFactory.makeAccount(primaryCurrency: .eur, enabledCurrencies: [.eur], accountGroup: group)
        let accountUah = TestDataFactory.makeAccount(primaryCurrency: .uah, enabledCurrencies: [.uah], accountGroup: group)
        group.accounts = [accountEur, accountUah]

        accountEur.transactions = [
            Transaction(kind: .income, amountMinor: 1000, currency: .eur, account: accountEur)
        ]
        accountUah.transactions = [
            Transaction(kind: .income, amountMinor: 2000, currency: .uah, account: accountUah)
        ]

        let rateProvider = MockRateProvider(rates: ["uah_eur": Decimal(string: "0.02") ?? 0])
        let service = AccountGroupBalanceService(rateProvider: rateProvider)

        let summary = await service.total(for: group, in: .eur, date: nil)

        #expect(summary.currency == .eur)
        #expect(summary.totalMinor == 1040)
        #expect(summary.missingAccounts.isEmpty)
    }

    @Test
    func totalsTrackMissingAccounts() async {
        let group = TestDataFactory.makeAccountGroup(name: "Main")
        let accountUah = TestDataFactory.makeAccount(primaryCurrency: .uah, enabledCurrencies: [.uah], accountGroup: group)
        group.accounts = [accountUah]

        accountUah.transactions = [
            Transaction(kind: .income, amountMinor: 2000, currency: .uah, account: accountUah)
        ]

        let rateProvider = MockRateProvider(rates: [:])
        let service = AccountGroupBalanceService(rateProvider: rateProvider)

        let summary = await service.total(for: group, in: .eur, date: nil)

        #expect(summary.totalMinor == 0)
        #expect(summary.missingAccounts.contains(where: { $0.id == accountUah.id }))
    }
}
