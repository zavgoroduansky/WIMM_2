import Foundation
import Combine

@MainActor
final class AccountsViewModel: ObservableObject {
    @Published var showNewTransaction = false
    @Published var preselectedAccountID: UUID?

    private(set) var accountGroups: [AccountGroup] = []

    func update(accountGroups: [AccountGroup]) {
        self.accountGroups = accountGroups
    }

    var orderedGroups: [AccountGroup] {
        accountGroups.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.name < rhs.name
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    func orderedAccounts(in group: AccountGroup) -> [Account] {
        group.accounts.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.name < rhs.name
            }
            return lhs.sortOrder < rhs.sortOrder
        }
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

@MainActor
final class AccountGroupHeaderViewModel: ObservableObject {
    @Published private(set) var summaryText = "Loading..."

    private let balanceService: AccountGroupBalanceServicing

    init(balanceService: AccountGroupBalanceServicing) {
        self.balanceService = balanceService
    }

    func loadSummary(accountGroup: AccountGroup, defaultCurrency: CurrencyCode) async {
        let summary = await balanceService.total(for: accountGroup, in: defaultCurrency, date: nil)
        var text = Money.format(minor: summary.totalMinor, currency: summary.currency)
        if !summary.missingAccounts.isEmpty {
            text += " (partial)"
        }
        summaryText = text
    }

    func taskID(accountGroup: AccountGroup, defaultCurrency: CurrencyCode) -> String {
        let accountsState = accountGroup.accounts
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map { account in
                let balances = account.balancesByCurrency
                    .sorted { $0.currency.rawValue < $1.currency.rawValue }
                    .map { "\($0.currency.rawValue):\($0.balanceMinor)" }
                    .joined(separator: ",")
                return "\(account.id.uuidString)|\(balances)"
            }
            .joined(separator: ";")

        return "\(accountGroup.id.uuidString)-\(defaultCurrency.rawValue)-\(accountsState)"
    }
}
