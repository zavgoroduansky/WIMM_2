import Foundation

struct HistoryEntry: Identifiable {
    let id: UUID
    let title: String
    let amountText: String
    let tone: HistoryEntryTone
    let date: Date
    let note: String?
    let transactionID: UUID?
    let transferGroupID: UUID?
}

enum HistoryEntryTone: Equatable {
    case income
    case expense
    case transfer
}

struct HistoryDaySection: Identifiable {
    let id: Date
    let date: Date
    let entries: [HistoryEntry]
}

struct HistoryUseCase {
    private let calendar: Calendar
    private let sectionTitleFormatter: DateFormatting

    init(calendar: Calendar, sectionTitleFormatter: DateFormatting) {
        self.calendar = calendar
        self.sectionTitleFormatter = sectionTitleFormatter
    }

    func makeEntries(from transactions: [Transaction]) -> [HistoryEntry] {
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
                        tone: .transfer,
                        date: max(expense.date, income.date),
                        note: expense.note ?? income.note,
                        transactionID: nil,
                        transferGroupID: groupID
                    )
                )
            } else {
                let title = tx.kind == .income ? (tx.category?.name ?? "Income") : (tx.category?.name ?? "Expense")
                result.append(
                    HistoryEntry(
                        id: tx.id,
                        title: title,
                        amountText: Money.format(minor: tx.amountMinor, currency: tx.currency),
                        tone: tx.kind == .income ? .income : .expense,
                        date: tx.date,
                        note: tx.note,
                        transactionID: tx.id,
                        transferGroupID: nil
                    )
                )
            }
        }

        return result.sorted { $0.date > $1.date }
    }

    func makeSections(from entries: [HistoryEntry]) -> [HistoryDaySection] {
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date)
        }

        let sortedDates = grouped.keys.sorted(by: >)
        return sortedDates.map { date in
            let items = grouped[date]?.sorted { $0.date > $1.date } ?? []
            return HistoryDaySection(id: date, date: date, entries: items)
        }
    }

    func sectionTitle(for date: Date, now: Date = .now) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        return sectionTitleFormatter.string(from: date)
    }
}
