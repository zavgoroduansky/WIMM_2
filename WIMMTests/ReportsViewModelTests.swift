import Foundation
import Testing
@testable import WIMM

@MainActor
struct ReportsViewModelTests {

    @Test
    func monthOptionsContainTransactionMonth() {
        let now = Date()
        let calendar = Calendar.current
        let txDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now

        let group = TestDataFactory.makeAccountGroup(name: "Main")
        let account = TestDataFactory.makeAccount(name: "Wallet", accountGroup: group)
        group.accounts = [account]
        let category = TestDataFactory.makeCategory(name: "Food", kind: .expense)

        let tx = Transaction(kind: .expense, amountMinor: 1000, currency: .eur, date: txDate, account: account, category: category)

        let viewModel = ReportsViewModel(rateProvider: MockRateProvider())
        let options = viewModel.monthOptions(from: [tx], calendar: calendar)

        let txMonth = calendar.dateInterval(of: .month, for: txDate)?.start
        #expect(txMonth != nil)
        #expect(options.contains(txMonth!))
    }

    @Test
    func loadReportAggregatesAndConvertsExpense() async {
        let calendar = Calendar.current
        let selectedDate = Date()
        let selectedMonthStart = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate

        let group = TestDataFactory.makeAccountGroup(name: "Main")
        let account = TestDataFactory.makeAccount(name: "Wallet", primaryCurrency: .uah, accountGroup: group)
        group.accounts = [account]
        let expenseCategory = TestDataFactory.makeCategory(name: "Food", kind: .expense)
        let incomeCategory = TestDataFactory.makeCategory(name: "Salary", kind: .income)

        let expense = Transaction(
            kind: .expense,
            amountMinor: 10_000,
            currency: .uah,
            date: selectedDate,
            account: account,
            category: expenseCategory
        )

        let income = Transaction(
            kind: .income,
            amountMinor: 5_000,
            currency: .uah,
            date: selectedDate,
            account: account,
            category: incomeCategory
        )

        let transferExpense = Transaction(
            kind: .expense,
            amountMinor: 3_000,
            currency: .uah,
            date: selectedDate,
            transferGroupId: UUID(),
            account: account,
            category: nil
        )

        let rateProvider = MockRateProvider(rates: ["uah_eur": Decimal(string: "0.02") ?? 0])
        let viewModel = ReportsViewModel(rateProvider: rateProvider)
        viewModel.selectedMonthStart = selectedMonthStart

        await viewModel.loadReport(
            transactions: [expense, income, transferExpense],
            defaultCurrency: .eur,
            calendar: calendar
        )

        #expect(viewModel.totalExpenseMinor == 200)
        #expect(viewModel.totalIncomeMinor == 100)
        #expect(viewModel.items.count == 1)
        #expect(viewModel.items.first?.category == "Food")
        #expect(viewModel.items.first?.totalMinor == 200)
        #expect(viewModel.missingCount == 0)
    }
}
