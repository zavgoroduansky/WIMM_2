import SwiftUI
import SwiftData

struct AccountsView: View {
    @Query(sort: [SortDescriptor(\AccountGroup.name)])
    private var accountGroups: [AccountGroup]

    @AppStorage("defaultCurrency") private var defaultCurrencyRaw = CurrencyCode.eur.rawValue
    @State private var showNewTransaction = false
    @State private var preselectedAccountID: UUID?

    var body: some View {
        NavigationStack {
            List {
                if accountGroups.isEmpty {
                    ContentUnavailableView(
                        "No Account Groups",
                        systemImage: "folder",
                        description: Text("Create account groups and accounts in Settings.")
                    )
                } else {
                    ForEach(orderedGroups) { accountGroup in
                        Section {
                            if accountGroup.accounts.isEmpty {
                                Text("No accounts in this group")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(orderedAccounts(in: accountGroup)) { account in
                                    HStack(alignment: .top) {
                                        Label(account.name, systemImage: account.iconName ?? "wallet.pass")
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            ForEach(account.balancesByCurrency, id: \.currency) { item in
                                                Text(Money.format(minor: item.balanceMinor, currency: item.currency))
                                                    .foregroundStyle(item.balanceMinor < 0 ? .red : .primary)
                                            }
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        preselectedAccountID = account.id
                                        showNewTransaction = true
                                    }
                                }
                            }
                        } header: {
                            AccountGroupHeaderView(
                                accountGroup: accountGroup,
                                defaultCurrency: CurrencyCode(rawValue: defaultCurrencyRaw) ?? .eur
                            )
                        }
                    }
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New", systemImage: "plus") {
                        preselectedAccountID = nil
                        showNewTransaction = true
                    }
                }
            }
            .sheet(isPresented: $showNewTransaction) {
                NewTransactionView(defaultMode: .expense, preselectedAccountID: preselectedAccountID)
            }
        }
    }

    private var orderedGroups: [AccountGroup] {
        accountGroups.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.name < rhs.name
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    private func orderedAccounts(in group: AccountGroup) -> [Account] {
        group.accounts.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.name < rhs.name
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }
}

private struct AccountGroupHeaderView: View {
    let accountGroup: AccountGroup
    let defaultCurrency: CurrencyCode

    @State private var summaryText = "Loading..."
    private let balanceService = AccountGroupBalanceService(rateProvider: FrankfurterRateProvider())

    var body: some View {
        HStack {
            Text(accountGroup.name)
            Spacer()
            Text(summaryText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .task(id: taskID) {
            let summary = await balanceService.total(for: accountGroup, in: defaultCurrency)
            var text = Money.format(minor: summary.totalMinor, currency: summary.currency)
            if !summary.missingAccounts.isEmpty {
                text += " (partial)"
            }
            summaryText = text
        }
    }

    private var taskID: String {
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
