import SwiftUI
import SwiftData

struct AccountsView: View {
    @Query(sort: [SortDescriptor(\AccountGroup.name)])
    private var accountGroups: [AccountGroup]

    @AppStorage("defaultCurrency") private var defaultCurrencyRaw = CurrencyCode.eur.rawValue
    @StateObject private var viewModel = AccountsViewModel()

    var body: some View {
        NavigationStack {
            List {
                if viewModel.orderedGroups.isEmpty {
                    ContentUnavailableView(
                        "No Account Groups",
                        systemImage: "folder",
                        description: Text("Create account groups and accounts in Settings.")
                    )
                } else {
                    ForEach(viewModel.orderedGroups) { accountGroup in
                        Section {
                            if accountGroup.accounts.isEmpty {
                                Text("No accounts in this group")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(viewModel.orderedAccounts(in: accountGroup)) { account in
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
                                        viewModel.didTapAccount(account)
                                    }
                                }
                            }
                        } header: {
                            AccountGroupHeaderView(
                                accountGroup: accountGroup,
                                defaultCurrency: CurrencyCode(rawValue: defaultCurrencyRaw) ?? .eur,
                                balanceService: AccountGroupBalanceService(rateProvider: FrankfurterRateProvider())
                            )
                        }
                    }
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New", systemImage: "plus") {
                        viewModel.didTapNew()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showNewTransaction) {
                NewTransactionView(defaultMode: .expense, preselectedAccountID: viewModel.preselectedAccountID)
            }
            .task(id: accountsSyncKey) {
                viewModel.update(accountGroups: accountGroups)
            }
        }
    }

    private var accountsSyncKey: String {
        accountGroups
            .map { group in
                "\(group.id.uuidString):\(group.accounts.count):\(group.sortOrder)"
            }
            .sorted()
            .joined(separator: "|")
    }
}

private struct AccountGroupHeaderView: View {
    let accountGroup: AccountGroup
    let defaultCurrency: CurrencyCode

    @StateObject private var viewModel: AccountGroupHeaderViewModel

    init(
        accountGroup: AccountGroup,
        defaultCurrency: CurrencyCode,
        balanceService: AccountGroupBalanceServicing
    ) {
        self.accountGroup = accountGroup
        self.defaultCurrency = defaultCurrency
        _viewModel = StateObject(wrappedValue: AccountGroupHeaderViewModel(balanceService: balanceService))
    }

    var body: some View {
        HStack {
            Text(accountGroup.name)
            Spacer()
            Text(viewModel.summaryText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .task(id: viewModel.taskID(accountGroup: accountGroup, defaultCurrency: defaultCurrency)) {
            await viewModel.loadSummary(accountGroup: accountGroup, defaultCurrency: defaultCurrency)
        }
    }
}
