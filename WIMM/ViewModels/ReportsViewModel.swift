import Foundation
import Combine

@MainActor
final class ReportsViewModel: ObservableObject {
    enum ChartType: String, CaseIterable, Identifiable {
        case bar
        case pie

        var id: String { rawValue }

        var title: String {
            switch self {
            case .bar: return "Bar"
            case .pie: return "Pie"
            }
        }
    }

    struct CategoryChartItem: Identifiable {
        let id = UUID()
        let category: String
        let totalMinor: Int64
        let colorHex: String?

        var total: Double {
            Double(totalMinor) / 100.0
        }
    }

    @Published var chartType: ChartType = .bar
    @Published var selectedMonthStart: Date
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var items: [CategoryChartItem] = []
    @Published private(set) var totalExpenseMinor: Int64 = 0
    @Published private(set) var totalIncomeMinor: Int64 = 0
    @Published private(set) var missingCount = 0

    private let rateProvider: ExchangeRateProvider

    init(
        rateProvider: ExchangeRateProvider,
        calendar: Calendar = .current
    ) {
        self.rateProvider = rateProvider
        self.selectedMonthStart = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
    }

    func monthOptions(from transactions: [Transaction], calendar: Calendar = .current) -> [Date] {
        var starts = Set<Date>()
        starts.insert(calendar.dateInterval(of: .month, for: .now)?.start ?? .now)

        for tx in transactions {
            if let monthStart = calendar.dateInterval(of: .month, for: tx.date)?.start {
                starts.insert(monthStart)
            }
        }

        return starts.sorted(by: >)
    }

    var monthOptions: [Date] {
        monthOptions(from: transactions)
    }

    func loadTransactions(using repository: FinanceRepositorying) {
        transactions = (try? repository.fetchTransactions()) ?? []
    }

    func ensureSelectedMonth(in options: [Date]) {
        guard !options.isEmpty else { return }
        if !options.contains(selectedMonthStart), let first = options.first {
            selectedMonthStart = first
        }
    }

    func monthLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }

    func taskKey(transactions: [Transaction], defaultCurrency: CurrencyCode) -> String {
        "\(selectedMonthStart.timeIntervalSince1970)-\(chartType.rawValue)-\(defaultCurrency.rawValue)-\(transactions.count)"
    }

    func taskKey(defaultCurrency: CurrencyCode) -> String {
        taskKey(transactions: transactions, defaultCurrency: defaultCurrency)
    }

    func loadReport(
        transactions: [Transaction],
        defaultCurrency: CurrencyCode,
        calendar: Calendar = .current
    ) async {
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

        items = expenseByCategory
            .map { CategoryChartItem(category: $0.key.name, totalMinor: $0.value, colorHex: $0.key.colorHex) }
            .sorted { $0.totalMinor > $1.totalMinor }
        totalExpenseMinor = expenseTotal
        totalIncomeMinor = incomeTotal
        missingCount = missing
    }

    func loadReport(defaultCurrency: CurrencyCode, calendar: Calendar = .current) async {
        await loadReport(transactions: transactions, defaultCurrency: defaultCurrency, calendar: calendar)
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
