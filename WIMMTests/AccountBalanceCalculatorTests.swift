import Testing
@testable import WIMM

struct AccountBalanceCalculatorTests {
    @Test
    func openingBalanceAppliesOnlyToPrimaryCurrency() {
        let calculator = AccountBalanceCalculator()
        let group = TestDataFactory.makeAccountGroup()
        let account = TestDataFactory.makeAccount(primaryCurrency: .eur, accountGroup: group)

        let incomeEur = Transaction(kind: .income, amountMinor: 500, currency: .eur, account: account)
        let expenseEur = Transaction(kind: .expense, amountMinor: 200, currency: .eur, account: account)
        let incomeUsd = Transaction(kind: .income, amountMinor: 1000, currency: .usd, account: account)

        let eurBalance = calculator.currentBalanceMinor(
            for: .eur,
            primaryCurrency: .eur,
            openingBalanceMinor: 1000,
            transactions: [incomeEur, expenseEur, incomeUsd]
        )
        let usdBalance = calculator.currentBalanceMinor(
            for: .usd,
            primaryCurrency: .eur,
            openingBalanceMinor: 1000,
            transactions: [incomeEur, expenseEur, incomeUsd]
        )

        #expect(eurBalance == 1300)
        #expect(usdBalance == 1000)
    }

    @Test
    func balancesByCurrencyReturnsForEnabledCurrencies() {
        let calculator = AccountBalanceCalculator()
        let group = TestDataFactory.makeAccountGroup()
        let account = TestDataFactory.makeAccount(primaryCurrency: .eur, accountGroup: group)

        let txs = [
            Transaction(kind: .income, amountMinor: 500, currency: .eur, account: account),
            Transaction(kind: .income, amountMinor: 700, currency: .usd, account: account)
        ]

        let result = calculator.balancesByCurrency(
            enabledCurrencies: [.eur, .usd],
            primaryCurrency: .eur,
            openingBalanceMinor: 0,
            transactions: txs
        )

        let map = Dictionary(uniqueKeysWithValues: result.map { ($0.currency, $0.balanceMinor) })
        #expect(map[.eur] == 500)
        #expect(map[.usd] == 700)
    }
}
