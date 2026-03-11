import Foundation
import SwiftData
import Testing
@testable import WIMM

@MainActor
struct ManageAccountsViewModelTests {
    @Test
    func moveGroupsUpdatesSortOrder() throws {
        let context = try TestDataFactory.makeInMemoryContext()
        let repository = SwiftDataFinanceRepository(
            modelContext: context,
            transactionService: TransactionService()
        )
        let g1 = TestDataFactory.makeAccountGroup(name: "A", sortOrder: 0)
        let g2 = TestDataFactory.makeAccountGroup(name: "B", sortOrder: 1)

        context.insert(g1)
        context.insert(g2)

        let vm = ManageAccountsViewModel(repository: repository)

        vm.moveGroups(from: IndexSet(integer: 0), to: 2, current: [g1, g2])

        #expect(g2.sortOrder == 0)
        #expect(g1.sortOrder == 1)
    }

    @Test
    func canDeleteAccountIsFalseWhenTransactionsExist() {
        let group = TestDataFactory.makeAccountGroup(name: "Main")
        let account = TestDataFactory.makeAccount(name: "Wallet", accountGroup: group)
        group.accounts = [account]

        let tx = Transaction(kind: .expense, amountMinor: 100, currency: .eur, account: account)
        let repo = MockFinanceRepository()
        repo.seed(groups: [group], categories: [], transactions: [tx])

        let vm = ManageAccountsViewModel(repository: repo)
        vm.load()

        #expect(!vm.canDeleteAccount(account))
        #expect(vm.deleteAccountBlockedReason(account) != nil)
    }

    @Test
    func updateAccountDoesNotChangeStructureWhenTransactionsExist() {
        let groupA = TestDataFactory.makeAccountGroup(name: "A")
        let groupB = TestDataFactory.makeAccountGroup(name: "B")
        let account = TestDataFactory.makeAccount(name: "Wallet", primaryCurrency: .eur, enabledCurrencies: [.eur], accountGroup: groupA)
        groupA.accounts = [account]

        let tx = Transaction(kind: .expense, amountMinor: 100, currency: .eur, account: account)
        let repo = MockFinanceRepository()
        repo.seed(groups: [groupA, groupB], categories: [], transactions: [tx])

        let vm = ManageAccountsViewModel(repository: repo)
        vm.load()

        vm.updateAccount(
            account,
            name: "New Name",
            iconName: "star",
            primaryCurrency: .usd,
            enabledCurrencies: [.usd],
            accountGroup: groupB
        )

        #expect(account.name == "New Name")
        #expect(account.iconName == "star")
        #expect(account.primaryCurrency == .eur)
        #expect(account.accountGroup.id == groupA.id)
    }

    @Test
    func updateAccountChangesStructureWhenNoTransactionsExist() {
        let groupA = TestDataFactory.makeAccountGroup(name: "A")
        let groupB = TestDataFactory.makeAccountGroup(name: "B")
        let account = TestDataFactory.makeAccount(name: "Wallet", primaryCurrency: .eur, enabledCurrencies: [.eur], accountGroup: groupA)
        groupA.accounts = [account]

        let repo = MockFinanceRepository()
        repo.seed(groups: [groupA, groupB], categories: [], transactions: [])

        let vm = ManageAccountsViewModel(repository: repo)
        vm.load()

        vm.updateAccount(
            account,
            name: "New Name",
            iconName: "star",
            primaryCurrency: .usd,
            enabledCurrencies: [.usd],
            accountGroup: groupB
        )

        #expect(account.name == "New Name")
        #expect(account.iconName == "star")
        #expect(account.primaryCurrency == .usd)
        #expect(account.accountGroup.id == groupB.id)
    }
}
