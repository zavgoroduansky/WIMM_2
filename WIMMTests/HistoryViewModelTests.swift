import Foundation
import Testing
@testable import WIMM

@MainActor
struct HistoryViewModelTests {
    @Test
    func groupsTransferIntoSingleEntry() {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let from = TestDataFactory.makeAccount(name: "From", accountGroup: group)
        let to = TestDataFactory.makeAccount(name: "To", accountGroup: group)
        let transferID = UUID()

        let outflow = Transaction(kind: .expense, amountMinor: 1000, currency: .eur, date: .now, note: "move", transferGroupId: transferID, account: from)
        let inflow = Transaction(kind: .income, amountMinor: 1200, currency: .usd, date: .now, note: "move", transferGroupId: transferID, account: to)

        let vm = HistoryViewModel()
        let entries = vm.entries(from: [outflow, inflow])

        #expect(entries.count == 1)
        #expect(entries.first?.tone == .transfer)
        #expect(entries.first?.title.contains("Transfer") == true)
    }

    @Test
    func deleteTransferRemovesBothTransactions() {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let from = TestDataFactory.makeAccount(name: "From", accountGroup: group)
        let to = TestDataFactory.makeAccount(name: "To", accountGroup: group)
        let transferID = UUID()

        let outflow = Transaction(kind: .expense, amountMinor: 1000, currency: .eur, date: .now, transferGroupId: transferID, account: from)
        let inflow = Transaction(kind: .income, amountMinor: 1200, currency: .usd, date: .now, transferGroupId: transferID, account: to)

        let repo = MockFinanceRepository()
        repo.seed(groups: [group], categories: [], transactions: [outflow, inflow])

        let vm = HistoryViewModel()
        vm.load(using: repo)

        let entry = vm.entries.first { $0.transferGroupID == transferID }
        #expect(entry != nil)

        if let entry {
            vm.delete(entry: entry, using: repo)
        }

        #expect(repo.transactions.isEmpty)
        #expect(repo.deleteCalls == 2)
    }

    @Test
    func deleteSingleTransactionRemovesOne() {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let account = TestDataFactory.makeAccount(name: "Wallet", accountGroup: group)
        let tx = Transaction(kind: .expense, amountMinor: 1000, currency: .eur, date: .now, account: account)

        let repo = MockFinanceRepository()
        repo.seed(groups: [group], categories: [], transactions: [tx])

        let vm = HistoryViewModel()
        vm.load(using: repo)

        let entry = vm.entries.first { $0.transactionID == tx.id }
        #expect(entry != nil)

        if let entry {
            vm.delete(entry: entry, using: repo)
        }

        #expect(repo.transactions.isEmpty)
        #expect(repo.deleteCalls == 1)
    }
}
