import Foundation
import Combine

@MainActor
final class AccountsViewModel: ObservableObject {
    @Published var showNewTransaction = false
    @Published var preselectedAccountID: UUID?
    @Published private(set) var accountGroups: [AccountGroup] = []
    private let repository: FinanceRepositorying

    init(repository: FinanceRepositorying) {
        self.repository = repository
    }

    func load() {
        accountGroups = (try? repository.fetchAccountGroups()) ?? []
    }

    var orderedGroups: [AccountGroup] {
        orderedGroups(from: accountGroups)
    }

    func orderedGroups(from accountGroups: [AccountGroup]) -> [AccountGroup] {
        accountGroups.sortedByOrderThenName()
    }

    func orderedAccounts(in group: AccountGroup) -> [Account] {
        group.accounts.sortedByOrderThenName()
    }

    func didTapAccount(_ account: Account) {
        preselectedAccountID = account.id
        showNewTransaction = true
    }

    func didTapNew() {
        preselectedAccountID = nil
        showNewTransaction = true
    }
}
