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

    @Published var chartType: ChartType = .bar
    @Published var selectedMonthStart: Date
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var items: [ReportsUseCase.CategoryChartItem] = []
    @Published private(set) var totalExpenseMinor: Int64 = 0
    @Published private(set) var totalIncomeMinor: Int64 = 0
    @Published private(set) var missingCount = 0

    private let repository: FinanceRepositorying
    private let useCase: ReportsUseCase
    private let monthLabelFormatter: DateFormatting

    init(
        repository: FinanceRepositorying,
        useCase: ReportsUseCase,
        selectedMonthStart: Date? = nil,
        monthLabelFormatter: DateFormatting
    ) {
        self.repository = repository
        self.useCase = useCase
        self.selectedMonthStart = selectedMonthStart ?? useCase.defaultSelectedMonthStart()
        self.monthLabelFormatter = monthLabelFormatter
    }

    func monthOptions(from transactions: [Transaction], calendar: Calendar = .current) -> [Date] {
        ReportsUseCase.monthOptions(from: transactions, calendar: calendar)
    }

    var monthOptions: [Date] {
        monthOptions(from: transactions)
    }

    func loadTransactions() {
        transactions = (try? repository.fetchTransactions()) ?? []
    }

    func ensureSelectedMonth(in options: [Date]) {
        guard !options.isEmpty else { return }
        if !options.contains(selectedMonthStart), let first = options.first {
            selectedMonthStart = first
        }
    }

    func monthLabel(for date: Date) -> String {
        monthLabelFormatter.string(from: date)
    }

    func taskKey(transactions: [Transaction], defaultCurrency: CurrencyCode) -> String {
        let signature = transactionsSignature(transactions)
        return "\(selectedMonthStart.timeIntervalSince1970)-\(chartType.rawValue)-\(defaultCurrency.rawValue)-\(signature)"
    }

    func taskKey(defaultCurrency: CurrencyCode) -> String {
        taskKey(transactions: transactions, defaultCurrency: defaultCurrency)
    }

    func loadReport(
        transactions: [Transaction],
        defaultCurrency: CurrencyCode,
        calendar: Calendar = .current
    ) async {
        let result = await useCase.buildReport(
            transactions: transactions,
            defaultCurrency: defaultCurrency,
            selectedMonthStart: selectedMonthStart
        )
        items = result.items
        totalExpenseMinor = result.totalExpenseMinor
        totalIncomeMinor = result.totalIncomeMinor
        missingCount = result.missingCount
    }

    func loadReport(defaultCurrency: CurrencyCode, calendar: Calendar = .current) async {
        await loadReport(transactions: transactions, defaultCurrency: defaultCurrency, calendar: calendar)
    }

    private func transactionsSignature(_ transactions: [Transaction]) -> String {
        let sorted = transactions.sorted { $0.id.uuidString < $1.id.uuidString }
        var hash: UInt64 = 14695981039346656037
        let prime: UInt64 = 1099511628211

        for tx in sorted {
            let payload = "\(tx.id.uuidString)|\(tx.kind.rawValue)|\(tx.amountMinor)|\(tx.currency.rawValue)|\(tx.date.timeIntervalSince1970)|\(tx.transferGroupId?.uuidString ?? "-")"
            for byte in payload.utf8 {
                hash ^= UInt64(byte)
                hash &*= prime
            }
        }

        return String(hash, radix: 16)
    }
}
