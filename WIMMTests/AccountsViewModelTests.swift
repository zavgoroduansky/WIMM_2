import Foundation
import Testing
@testable import WIMM

@MainActor
struct AccountsViewModelTests {
    @Test
    func ordersGroupsAndAccountsBySortOrderThenName() throws {
        let context = try TestDataFactory.makeInMemoryContext()
        let repository = SwiftDataFinanceRepository(modelContext: context)
        let g1 = TestDataFactory.makeAccountGroup(name: "B", sortOrder: 1)
        let g2 = TestDataFactory.makeAccountGroup(name: "A", sortOrder: 0)

        let a1 = TestDataFactory.makeAccount(name: "B", sortOrder: 1, accountGroup: g2)
        let a2 = TestDataFactory.makeAccount(name: "A", sortOrder: 0, accountGroup: g2)
        g2.accounts = [a1, a2]

        let vm = AccountsViewModel(repository: repository)

        #expect(vm.orderedGroups(from: [g1, g2]).map(\.name) == ["A", "B"])
        #expect(vm.orderedAccounts(in: g2).map(\.name) == ["A", "B"])
    }

    @Test
    func tapAccountOpensTransactionWithPreselectedAccount() throws {
        let context = try TestDataFactory.makeInMemoryContext()
        let repository = SwiftDataFinanceRepository(modelContext: context)
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let account = TestDataFactory.makeAccount(name: "Wallet", accountGroup: group)
        let vm = AccountsViewModel(repository: repository)

        vm.didTapAccount(account)

        #expect(vm.showNewTransaction)
        #expect(vm.preselectedAccountID == account.id)
    }

    @Test
    func tapNewClearsPreselectedAccount() throws {
        let context = try TestDataFactory.makeInMemoryContext()
        let repository = SwiftDataFinanceRepository(modelContext: context)
        let vm = AccountsViewModel(repository: repository)
        vm.preselectedAccountID = UUID()

        vm.didTapNew()

        #expect(vm.showNewTransaction)
        #expect(vm.preselectedAccountID == nil)
    }
}
