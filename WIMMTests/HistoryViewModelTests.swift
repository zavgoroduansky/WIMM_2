import Foundation
import Testing
@testable import WIMM

@MainActor
struct HistoryViewModelTests {

    @Test
    func deleteTransferEntryRemovesGroupTransactions() {
        let group = TestDataFactory.makeAccountGroup(name: "Main")
        let from = TestDataFactory.makeAccount(name: "From", accountGroup: group)
        let to = TestDataFactory.makeAccount(name: "To", accountGroup: group)
        group.accounts = [from, to]

        let groupID = UUID()
        let outflow = Transaction(
            kind: .expense,
            amountMinor: 1_000,
            currency: .eur,
            date: Date(),
            transferGroupId: groupID,
            account: from
        )
        let inflow = Transaction(
            kind: .income,
            amountMinor: 1_000,
            currency: .eur,
            date: Date(),
            transferGroupId: groupID,
            account: to
        )

        let repo = MockFinanceRepository()
        repo.seed(groups: [group], categories: [], transactions: [outflow, inflow])

        let useCase = HistoryUseCase(
            calendar: Calendar.current,
            sectionTitleFormatter: DateFormatterFactory.historySectionTitle()
        )
        let viewModel = HistoryViewModel(repository: repo, useCase: useCase)
        viewModel.load()

        let transferEntry = viewModel.entries.first { $0.transferGroupID == groupID }
        #expect(transferEntry != nil)

        if let entry = transferEntry {
            viewModel.delete(entry: entry)
        }

        #expect(repo.deleteCalls == 2)
        #expect(repo.transactions.isEmpty)
    }

    @Test
    func sectionTitleUsesTodayYesterdayFallbacks() {
        let repo = MockFinanceRepository()
        let useCase = HistoryUseCase(
            calendar: Calendar.current,
            sectionTitleFormatter: DateFormatterFactory.historySectionTitle()
        )
        let viewModel = HistoryViewModel(repository: repo, useCase: useCase)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        #expect(viewModel.sectionTitle(for: today) == "Today")
        #expect(viewModel.sectionTitle(for: yesterday) == "Yesterday")
    }
}
