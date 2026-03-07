import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    enum EntryTone: Equatable {
        case income
        case expense
        case transfer
    }

    struct Entry: Identifiable {
        let id: UUID
        let title: String
        let amountText: String
        let tone: EntryTone
        let date: Date
        let note: String?
    }

    @Published var showNewTransaction = false

    private(set) var transactions: [Transaction] = []

    func update(transactions: [Transaction]) {
        self.transactions = transactions
    }

    var entries: [Entry] {
        var result: [Entry] = []
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
                    Entry(
                        id: groupID,
                        title: "Transfer: \(fromLabel) → \(toLabel)",
                        amountText: amountText,
                        tone: .transfer,
                        date: max(expense.date, income.date),
                        note: expense.note ?? income.note
                    )
                )
            } else {
                let title = tx.kind == .income ? (tx.category?.name ?? "Income") : (tx.category?.name ?? "Expense")
                result.append(
                    Entry(
                        id: tx.id,
                        title: title,
                        amountText: Money.format(minor: tx.amountMinor, currency: tx.currency),
                        tone: tx.kind == .income ? .income : .expense,
                        date: tx.date,
                        note: tx.note
                    )
                )
            }
        }

        return result.sorted { $0.date > $1.date }
    }

    func didTapNew() {
        showNewTransaction = true
    }
}
