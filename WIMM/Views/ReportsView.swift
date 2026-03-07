import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    enum MonthSelection: String, CaseIterable, Identifiable {
        case current
        case previous

        var id: String { rawValue }

        var title: String {
            switch self {
            case .current: return "This Month"
            case .previous: return "Previous"
            }
        }
    }

    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse)])
    private var transactions: [Transaction]

    @AppStorage("defaultCurrency") private var defaultCurrencyRaw = CurrencyCode.eur.rawValue

    @State private var monthSelection: MonthSelection = .current
    @State private var items: [CategoryChartItem] = []
    @State private var totalExpenseMinor: Int64 = 0
    @State private var totalIncomeMinor: Int64 = 0
    @State private var missingCount = 0

    private let rateProvider = FrankfurterRateProvider()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Period", selection: $monthSelection) {
                        ForEach(MonthSelection.allCases) { period in
                            Text(period.title).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)

                    if items.isEmpty {
                        ContentUnavailableView(
                            "No Data",
                            systemImage: "chart.bar",
                            description: Text("No expenses for selected period.")
                        )
                    } else {
                        Chart(items) { item in
                            BarMark(
                                x: .value("Category", item.category),
                                y: .value("Amount", item.total)
                            )
                            .foregroundStyle(.red.gradient)
                        }
                        .frame(height: 260)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Totals")
                            .font(.headline)
                        Text("Expense: \(Money.format(minor: totalExpenseMinor, currency: defaultCurrency))")
                        Text("Income: \(Money.format(minor: totalIncomeMinor, currency: defaultCurrency))")
                        Text("Net: \(Money.format(minor: totalIncomeMinor - totalExpenseMinor, currency: defaultCurrency))")
                    }

                    if missingCount > 0 {
                        Text("Some values could not be converted (\(missingCount)). Totals are partial.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Reports")
            .task(id: taskKey) {
                await loadReport()
            }
        }
    }

    private var defaultCurrency: CurrencyCode {
        CurrencyCode(rawValue: defaultCurrencyRaw) ?? .eur
    }

    private var taskKey: String {
        "\(monthSelection.rawValue)-\(defaultCurrency.rawValue)-\(transactions.count)"
    }

    private func loadReport() async {
        let calendar = Calendar.current
        let now = Date()
        let monthDate: Date
        switch monthSelection {
        case .current:
            monthDate = now
        case .previous:
            monthDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        }

        let filtered = transactions.filter { tx in
            tx.transferGroupId == nil && calendar.isDate(tx.date, equalTo: monthDate, toGranularity: .month)
        }

        var expenseByCategory: [String: Int64] = [:]
        var expenseTotal: Int64 = 0
        var incomeTotal: Int64 = 0
        var missing = 0

        for tx in filtered {
            do {
                let converted: Int64
                if tx.currency == defaultCurrency {
                    converted = tx.amountMinor
                } else {
                    converted = try await rateProvider.convert(
                        minor: tx.amountMinor,
                        from: tx.currency,
                        to: defaultCurrency,
                        date: tx.date
                    )
                }

                if tx.kind == .expense {
                    expenseTotal += converted
                    let key = tx.category?.name ?? "Uncategorized"
                    expenseByCategory[key, default: 0] += converted
                } else {
                    incomeTotal += converted
                }
            } catch {
                missing += 1
            }
        }

        items = expenseByCategory
            .map { CategoryChartItem(category: $0.key, totalMinor: $0.value) }
            .sorted { $0.totalMinor > $1.totalMinor }
        totalExpenseMinor = expenseTotal
        totalIncomeMinor = incomeTotal
        missingCount = missing
    }
}

private struct CategoryChartItem: Identifiable {
    let id = UUID()
    let category: String
    let totalMinor: Int64

    var total: Double {
        Double(totalMinor) / 100.0
    }
}
