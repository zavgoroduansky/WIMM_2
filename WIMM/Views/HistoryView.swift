import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse)])
    private var transactions: [Transaction]
    @State private var showNewTransaction = false

    var body: some View {
        NavigationStack {
            List(entries) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.headline)
                        Text(entry.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let note = entry.note, !note.isEmpty {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Text(entry.amountText)
                        .foregroundStyle(entry.color)
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New", systemImage: "plus") {
                        showNewTransaction = true
                    }
                }
            }
            .sheet(isPresented: $showNewTransaction) {
                NewTransactionView(defaultMode: .expense)
            }
        }
    }

    private var entries: [HistoryEntry] {
        var result: [HistoryEntry] = []
        var handledTransfers: Set<UUID> = []
        let transferGroups = Dictionary(grouping: transactions.filter { $0.transferGroupId != nil }) {
            $0.transferGroupId!
        }

        for tx in transactions {
            if let groupID = tx.transferGroupId {
                guard !handledTransfers.contains(groupID), let grouped = transferGroups[groupID] else {
                    continue
                }
                handledTransfers.insert(groupID)

                let outflow = grouped.first { $0.kind == .expense }
                let inflow = grouped.first { $0.kind == .income }
                guard let expense = outflow, let income = inflow else { continue }

                let fromLabel = "\(expense.account.accountGroup.name) • \(expense.account.name)"
                let toLabel = "\(income.account.accountGroup.name) • \(income.account.name)"
                let amountText = "\(Money.format(minor: expense.amountMinor, currency: expense.currency)) → \(Money.format(minor: income.amountMinor, currency: income.currency))"
                result.append(
                    HistoryEntry(
                        id: groupID,
                        title: "Transfer: \(fromLabel) → \(toLabel)",
                        amountText: amountText,
                        color: .yellow,
                        date: max(expense.date, income.date),
                        note: expense.note ?? income.note
                    )
                )
            } else {
                let title = tx.kind == .income ? (tx.category?.name ?? "Income") : (tx.category?.name ?? "Expense")
                let color: Color = tx.kind == .income ? .green : .red
                result.append(
                    HistoryEntry(
                        id: tx.id,
                        title: title,
                        amountText: Money.format(minor: tx.amountMinor, currency: tx.currency),
                        color: color,
                        date: tx.date,
                        note: tx.note
                    )
                )
            }
        }

        return result.sorted { $0.date > $1.date }
    }
}

private struct HistoryEntry: Identifiable {
    let id: UUID
    let title: String
    let amountText: String
    let color: Color
    let date: Date
    let note: String?
}
