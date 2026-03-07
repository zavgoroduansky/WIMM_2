import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Query(sort: [SortDescriptor(\Category.name)])
    private var categories: [Category]
    @State private var showNewTransaction = false
    @State private var preselectedCategoryID: UUID?

    var body: some View {
        NavigationStack {
            List {
                if expenseCategories.isEmpty {
                    ContentUnavailableView(
                        "No Expense Categories",
                        systemImage: "tray",
                        description: Text("Create expense categories in Settings.")
                    )
                } else {
                    ForEach(expenseCategories) { category in
                        HStack {
                            Text(category.name)
                            Spacer()
                            Text(expenseForCurrentMonth(category))
                                .foregroundStyle(.red)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            preselectedCategoryID = category.id
                            showNewTransaction = true
                        }
                    }
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New", systemImage: "plus") {
                        preselectedCategoryID = nil
                        showNewTransaction = true
                    }
                }
            }
            .sheet(isPresented: $showNewTransaction) {
                NewTransactionView(defaultMode: .expense, preselectedCategoryID: preselectedCategoryID)
            }
        }
    }

    private func expenseForCurrentMonth(_ category: Category) -> String {
        let calendar = Calendar.current
        let now = Date()
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

    private var expenseCategories: [Category] {
        categories.filter { $0.kind == .expense }
    }
}
