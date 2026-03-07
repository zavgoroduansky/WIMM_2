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
        vm.update(transactions: [outflow, inflow])

        #expect(vm.entries.count == 1)
        #expect(vm.entries.first?.tone == .transfer)
        #expect(vm.entries.first?.title.contains("Transfer") == true)
    }
}
