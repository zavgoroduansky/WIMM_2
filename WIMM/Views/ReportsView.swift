import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse)])
    private var transactions: [Transaction]

    @AppStorage("defaultCurrency") private var defaultCurrencyRaw = CurrencyCode.eur.rawValue
    @StateObject private var viewModel: ReportsViewModel

    init() {
        _viewModel = StateObject(wrappedValue: ReportsViewModel(rateProvider: FrankfurterRateProvider()))
    }

    init(viewModel: ReportsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Month", selection: $viewModel.selectedMonthStart) {
                        ForEach(monthOptions, id: \.self) { month in
                            Text(viewModel.monthLabel(for: month)).tag(month)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Chart Type", selection: $viewModel.chartType) {
                        ForEach(ReportsViewModel.ChartType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)

                    if viewModel.items.isEmpty {
                        ContentUnavailableView(
                            "No Data",
                            systemImage: "chart.bar",
                            description: Text("No expenses for selected period.")
                        )
                    } else {
                        if viewModel.chartType == .bar {
                            Chart(viewModel.items) { item in
                                BarMark(
                                    x: .value("Category", item.category),
                                    y: .value("Amount", item.total)
                                )
                                .foregroundStyle(.green.gradient)
                            }
                            .frame(height: 260)
                        } else {
                            Chart(viewModel.items) { item in
                                SectorMark(
                                    angle: .value("Amount", item.total),
                                    innerRadius: .ratio(0.58),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(by: .value("Category", item.category))
                            }
                            .frame(height: 300)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Totals")
                            .font(.headline)
                        Text("Expense: \(Money.format(minor: viewModel.totalExpenseMinor, currency: defaultCurrency))")
                        Text("Income: \(Money.format(minor: viewModel.totalIncomeMinor, currency: defaultCurrency))")
                        Text("Net: \(Money.format(minor: viewModel.totalIncomeMinor - viewModel.totalExpenseMinor, currency: defaultCurrency))")
                    }

                    if viewModel.missingCount > 0 {
                        Text("Some values could not be converted (\(viewModel.missingCount)). Totals are partial.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Reports")
            .onChange(of: monthOptions) { _, newOptions in
                viewModel.ensureSelectedMonth(in: newOptions)
            }
            .task(id: viewModel.taskKey(transactions: transactions, defaultCurrency: defaultCurrency)) {
                await viewModel.loadReport(transactions: transactions, defaultCurrency: defaultCurrency)
            }
        }
    }

    private var defaultCurrency: CurrencyCode {
        CurrencyCode(rawValue: defaultCurrencyRaw) ?? .eur
    }

    private var monthOptions: [Date] {
        viewModel.monthOptions(from: transactions)
    }
}
