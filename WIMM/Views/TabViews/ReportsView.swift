import SwiftUI
import Charts

struct ReportsView: View {
    @AppStorage("defaultCurrency") private var defaultCurrencyRaw = CurrencyCode.eur.rawValue
    @ObservedObject var viewModel: ReportsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ReportsMonthPickerView(
                        monthOptions: monthOptions,
                        labelProvider: { viewModel.monthLabel(for: $0) },
                        selectedMonthStart: $viewModel.selectedMonthStart
                    )

                    ReportsChartTypePickerView(chartType: $viewModel.chartType)

                    ReportsChartView(items: viewModel.items, chartType: viewModel.chartType)

                    ReportsTotalsView(
                        totalExpenseMinor: viewModel.totalExpenseMinor,
                        totalIncomeMinor: viewModel.totalIncomeMinor,
                        currency: defaultCurrency
                    )

                    ReportsMissingRatesView(missingCount: viewModel.missingCount)
                }
                .padding()
            }
            .navigationTitle("Reports")
            .onAppear(perform: load)
            .onChange(of: monthOptions) { _, newOptions in
                viewModel.ensureSelectedMonth(in: newOptions)
            }
            .task(id: viewModel.taskKey(defaultCurrency: defaultCurrency)) {
                await viewModel.loadReport(defaultCurrency: defaultCurrency)
            }
        }
    }

    private var defaultCurrency: CurrencyCode {
        CurrencyCode(rawValue: defaultCurrencyRaw) ?? .eur
    }

    private var monthOptions: [Date] {
        viewModel.monthOptions
    }

    private func load() {
        viewModel.loadTransactions()
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let repository = PreviewSupport.makeRepository(context: context)
    let viewModel = ReportsViewModel(rateProvider: PreviewRateProvider(), repository: repository)
    viewModel.loadTransactions()

    return ReportsView(
        viewModel: viewModel
    )
}
