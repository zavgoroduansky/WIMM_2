import Foundation
import Testing
@testable import WIMM

@MainActor
struct ReportsUseCaseTests {
    @Test
    func monthOptionsIncludesCurrentMonthWhenNoTransactions() {
        let calendar = Calendar.current
        let useCase = ReportsUseCase(rateProvider: MockRateProvider(), calendar: calendar)

        let options = useCase.monthOptions(from: [])

        let currentStart = calendar.dateInterval(of: .month, for: .now)?.start
        #expect(currentStart != nil)
        #expect(options.contains(currentStart!))
    }

    @Test
    func buildReportIgnoresTransferTransactions() async {
        let calendar = Calendar.current
        let now = Date()
        let selectedMonthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now

        let group = TestDataFactory.makeAccountGroup()
        let account = TestDataFactory.makeAccount(accountGroup: group)
        let category = TestDataFactory.makeCategory(name: "Food", kind: .expense)

        let transferTx = Transaction(
            kind: .expense,
            amountMinor: 1_000,
            currency: .eur,
            date: now,
            transferGroupId: UUID(),
            account: account,
            category: category
        )

        let useCase = ReportsUseCase(rateProvider: MockRateProvider(), calendar: calendar)
        let result = await useCase.buildReport(
            transactions: [transferTx],
            defaultCurrency: .eur,
            selectedMonthStart: selectedMonthStart
        )

        #expect(result.items.isEmpty)
        #expect(result.totalExpenseMinor == 0)
        #expect(result.missingCount == 0)
    }

    @Test
    func buildReportAggregatesByCategoryAndSortsDesc() async {
        let calendar = Calendar.current
        let now = Date()
        let selectedMonthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now

        let group = TestDataFactory.makeAccountGroup()
        let account = TestDataFactory.makeAccount(accountGroup: group)
        let food = TestDataFactory.makeCategory(name: "Food", kind: .expense)
        let rent = TestDataFactory.makeCategory(name: "Rent", kind: .expense)

        let txA = Transaction(kind: .expense, amountMinor: 1_000, currency: .eur, date: now, account: account, category: food)
        let txB = Transaction(kind: .expense, amountMinor: 3_000, currency: .eur, date: now, account: account, category: rent)

        let useCase = ReportsUseCase(rateProvider: MockRateProvider(), calendar: calendar)
        let result = await useCase.buildReport(
            transactions: [txA, txB],
            defaultCurrency: .eur,
            selectedMonthStart: selectedMonthStart
        )

        #expect(result.items.count == 2)
        #expect(result.items.first?.category == "Rent")
        #expect(result.items.first?.totalMinor == 3_000)
        #expect(result.totalExpenseMinor == 4_000)
    }

    @Test
    func buildReportTracksMissingRates() async {
        let calendar = Calendar.current
        let now = Date()
        let selectedMonthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now

        let group = TestDataFactory.makeAccountGroup()
        let account = TestDataFactory.makeAccount(accountGroup: group)
        let category = TestDataFactory.makeCategory(name: "Food", kind: .expense)

        let tx = Transaction(kind: .expense, amountMinor: 1_000, currency: .uah, date: now, account: account, category: category)

        let useCase = ReportsUseCase(rateProvider: MockRateProvider(rates: [:]), calendar: calendar)
        let result = await useCase.buildReport(
            transactions: [tx],
            defaultCurrency: .eur,
            selectedMonthStart: selectedMonthStart
        )

        #expect(result.missingCount == 1)
        #expect(result.totalExpenseMinor == 0)
    }
}
