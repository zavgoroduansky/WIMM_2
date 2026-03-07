import Foundation

protocol AccountBalanceCalculating {
    func currentBalanceMinor(
        for currency: CurrencyCode,
        primaryCurrency: CurrencyCode,
        openingBalanceMinor: Int64,
        transactions: [Transaction]
    ) -> Int64

    func balancesByCurrency(
        enabledCurrencies: [CurrencyCode],
        primaryCurrency: CurrencyCode,
        openingBalanceMinor: Int64,
        transactions: [Transaction]
    ) -> [(currency: CurrencyCode, balanceMinor: Int64)]
}

final class AccountBalanceCalculator: AccountBalanceCalculating {
    func currentBalanceMinor(
        for currency: CurrencyCode,
        primaryCurrency: CurrencyCode,
        openingBalanceMinor: Int64,
        transactions: [Transaction]
    ) -> Int64 {
        let incomes = transactions
            .filter { $0.kind == .income && $0.currency == currency }
            .reduce(Int64.zero) { $0 + $1.amountMinor }

        let expenses = transactions
            .filter { $0.kind == .expense && $0.currency == currency }
            .reduce(Int64.zero) { $0 + $1.amountMinor }

        let opening = currency == primaryCurrency ? openingBalanceMinor : 0
        return opening + incomes - expenses
    }

    func balancesByCurrency(
        enabledCurrencies: [CurrencyCode],
        primaryCurrency: CurrencyCode,
        openingBalanceMinor: Int64,
        transactions: [Transaction]
    ) -> [(currency: CurrencyCode, balanceMinor: Int64)] {
        enabledCurrencies.map { currency in
            (
                currency,
                currentBalanceMinor(
                    for: currency,
                    primaryCurrency: primaryCurrency,
                    openingBalanceMinor: openingBalanceMinor,
                    transactions: transactions
                )
            )
        }
    }
}
