import Foundation
import Combine

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published var showNewTransaction = false
    @Published var preselectedCategoryID: UUID?

    private(set) var categories: [Category] = []

    func update(categories: [Category]) {
        self.categories = categories
    }

    var expenseCategories: [Category] {
        categories.filter { $0.kind == .expense }
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

    func didTapCategory(_ category: Category) {
        preselectedCategoryID = category.id
        showNewTransaction = true
    }

    func didTapNew() {
        preselectedCategoryID = nil
        showNewTransaction = true
    }
}
