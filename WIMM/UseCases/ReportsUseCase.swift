import Foundation

struct ReportsUseCase {
    struct CategoryChartItem: Identifiable {
        let id = UUID()
        let category: String
        let totalMinor: Int64
        let colorHex: String?

        var total: Double {
            Double(totalMinor) / 100.0
        }
    }

    struct ReportResult {
        let items: [CategoryChartItem]
        let totalExpenseMinor: Int64
        let totalIncomeMinor: Int64
        let missingCount: Int
    }

    private let rateProvider: ExchangeRateProvider
    private let calendar: Calendar

    init(rateProvider: ExchangeRateProvider, calendar: Calendar = .current) {
        self.rateProvider = rateProvider
        self.calendar = calendar
    }

    func monthOptions(from transactions: [Transaction]) -> [Date] {
        Self.monthOptions(from: transactions, calendar: calendar)
    }

    static func monthOptions(from transactions: [Transaction], calendar: Calendar = .current) -> [Date] {
        var starts = Set<Date>()
        starts.insert(calendar.dateInterval(of: .month, for: .now)?.start ?? .now)

        for tx in transactions {
            if let monthStart = calendar.dateInterval(of: .month, for: tx.date)?.start {
                starts.insert(monthStart)
            }
        }

        return starts.sorted(by: >)
    }

    func buildReport(
        transactions: [Transaction],
        defaultCurrency: CurrencyCode,
        selectedMonthStart: Date
    ) async -> ReportResult {
        let filtered = transactions.filter { tx in
            tx.transferGroupId == nil && calendar.isDate(tx.date, equalTo: selectedMonthStart, toGranularity: .month)
        }

        struct CategorySummaryKey: Hashable {
            let name: String
            let colorHex: String?
        }

        var expenseByCategory: [CategorySummaryKey: Int64] = [:]
        var expenseTotal: Int64 = 0
        var incomeTotal: Int64 = 0
        var missing = 0

        for tx in filtered {
            do {
                let converted = try await convert(
                    minor: tx.amountMinor,
                    from: tx.currency,
                    to: defaultCurrency,
                    date: tx.date
                )

                if tx.kind == .expense {
                    expenseTotal += converted
                    let key = CategorySummaryKey(
                        name: tx.category?.name ?? "Uncategorized",
                        colorHex: tx.category?.colorHex
                    )
                    expenseByCategory[key, default: 0] += converted
                } else {
                    incomeTotal += converted
                }
            } catch {
                missing += 1
            }
        }

        let items = expenseByCategory
            .map { CategoryChartItem(category: $0.key.name, totalMinor: $0.value, colorHex: $0.key.colorHex) }
            .sorted { $0.totalMinor > $1.totalMinor }

        return ReportResult(
            items: items,
            totalExpenseMinor: expenseTotal,
            totalIncomeMinor: incomeTotal,
            missingCount: missing
        )
    }

    private func convert(
        minor amountMinor: Int64,
        from: CurrencyCode,
        to: CurrencyCode,
        date: Date
    ) async throws -> Int64 {
        if from == to {
            return amountMinor
        }

        let rate = try await rateProvider.rate(from: from, to: to, on: date)
        let sourceAmount = Money.decimal(fromMinor: amountMinor)
        return Money.minor(fromDecimal: sourceAmount * rate)
    }
}
