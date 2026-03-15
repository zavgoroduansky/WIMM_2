import Foundation
import Combine

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published var showNewTransaction = false
    @Published var preselectedCategoryID: UUID?
    @Published private(set) var categories: [Category] = []

    private let repository: FinanceRepositorying

    init(repository: FinanceRepositorying) {
        self.repository = repository
    }

    func load() {
        categories = (try? repository.fetchCategories()) ?? []
    }

    var expenseCategories: [Category] {
        expenseCategories(from: categories)
    }

    func expenseCategories(from categories: [Category]) -> [Category] {
        categories
            .filter { $0.kind == .expense }
            .sorted {
                totalExpenseMinor(for: $0) > totalExpenseMinor(for: $1)
            }
    }

    func expenseForCurrentMonth(_ category: Category, now: Date = .now, calendar: Calendar = .current) -> String {
        let grouped = Dictionary(grouping: category.transactions
            .filter { tx in
                tx.kind == .expense && tx.transferGroupId == nil && calendar.isDate(tx.date, equalTo: now, toGranularity: .month)
            }, by: \.currency)

        let parts = CurrencyCode.allCases.compactMap { currency -> String? in
            guard let txs = grouped[currency], !txs.isEmpty else {
                return nil
            }
            let sum = txs.reduce(Int64.zero) { $0 + $1.amountMinor }
            return Money.format(minor: sum, currency: currency)
        }

        return parts.isEmpty ? "0" : parts.joined(separator: " · ")
    }

    func totalExpenseMinor(
        for category: Category,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int64 {
        category.transactions
            .filter { tx in
                tx.kind == .expense && tx.transferGroupId == nil && calendar.isDate(tx.date, equalTo: now, toGranularity: .month)
            }
            .reduce(Int64.zero) { $0 + $1.amountMinor }
    }

    func totalExpenseMinorAllCategories(
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int64 {
        expenseCategories(from: categories)
            .reduce(Int64.zero) { $0 + totalExpenseMinor(for: $1, now: now, calendar: calendar) }
    }

    func expenseProgressByCategory(
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [UUID: Double] {
        let total = totalExpenseMinorAllCategories(now: now, calendar: calendar)
        guard total > 0 else {
            return [:]
        }

        return expenseCategories(from: categories).reduce(into: [UUID: Double]()) { result, category in
            let categoryTotal = totalExpenseMinor(for: category, now: now, calendar: calendar)
            result[category.id] = Double(categoryTotal) / Double(total)
        }
    }

    func didTapCategory(_ category: Category) {
        preselectedCategoryID = category.id
        showNewTransaction = true
    }

    func didTapNew() {
        preselectedCategoryID = nil
        showNewTransaction = true
    }
}
