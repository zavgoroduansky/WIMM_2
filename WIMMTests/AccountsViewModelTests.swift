import Testing
@testable import WIMM

@MainActor
struct AccountsViewModelTests {
    @Test
    func ordersGroupsAndAccountsBySortOrderThenName() {
        let g1 = TestDataFactory.makeAccountGroup(name: "B", sortOrder: 1)
        let g2 = TestDataFactory.makeAccountGroup(name: "A", sortOrder: 0)

        let a1 = TestDataFactory.makeAccount(name: "B", sortOrder: 1, accountGroup: g2)
        let a2 = TestDataFactory.makeAccount(name: "A", sortOrder: 0, accountGroup: g2)
        g2.accounts = [a1, a2]

        let vm = AccountsViewModel()
        vm.update(accountGroups: [g1, g2])

        #expect(vm.orderedGroups.map(\.name) == ["A", "B"])
        #expect(vm.orderedAccounts(in: g2).map(\.name) == ["A", "B"])
    }

    @Test
    func tapAccountOpensTransactionWithPreselectedAccount() {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let account = TestDataFactory.makeAccount(name: "Wallet", accountGroup: group)
        let vm = AccountsViewModel()

        vm.didTapAccount(account)

        #expect(vm.showNewTransaction)
        #expect(vm.preselectedAccountID == account.id)
    }
}
