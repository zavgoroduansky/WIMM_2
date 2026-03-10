import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var showNewTransaction = false
    @Published private(set) var transactions: [Transaction] = []

    private let repository: FinanceRepositorying
    private let useCase: HistoryUseCase

    init(repository: FinanceRepositorying, useCase: HistoryUseCase) {
        self.repository = repository
        self.useCase = useCase
    }

    func load() {
        transactions = (try? repository.fetchTransactions()) ?? []
    }

    var entries: [HistoryEntry] {
        useCase.makeEntries(from: transactions)
    }

    var sections: [HistoryDaySection] {
        useCase.makeSections(from: entries)
    }

    func didTapNew() {
        showNewTransaction = true
    }

    func delete(entry: HistoryEntry) {
        if let transferGroupID = entry.transferGroupID {
            transactions
                .filter { $0.transferGroupId == transferGroupID }
                .forEach { repository.delete($0) }
        } else if let transactionID = entry.transactionID,
                  let transaction = transactions.first(where: { $0.id == transactionID }) {
            repository.delete(transaction)
        } else {
            return
        }

        try? repository.save()
        load()
    }

    func sectionTitle(for date: Date) -> String {
        useCase.sectionTitle(for: date)
    }
}
