import SwiftUI
import SwiftData

struct AccountsView: View {
    @AppStorage("defaultCurrency") private var defaultCurrencyRaw = CurrencyCode.eur.rawValue
    @ObservedObject var viewModel: AccountsViewModel
    let makeBalanceService: () -> AccountGroupBalanceServicing
    let makeNewTransactionView: (_ defaultMode: NewTransactionViewModel.TransactionMode, _ preselectedAccountID: UUID?, _ preselectedCategoryID: UUID?) -> AnyView

    var body: some View {
        NavigationStack {
            List {
                if viewModel.orderedGroups(from: accountGroups).isEmpty {
                    emptyState
                } else {
                    accountsSections
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
                makeNewTransactionView(.expense, viewModel.preselectedAccountID, nil)
            }
            .onAppear(perform: load)
            .onChange(of: viewModel.showNewTransaction) { _, isPresented in
                if !isPresented {
                    load()
                }
            }
        }
    }

    private var accountGroups: [AccountGroup] {
        viewModel.accountGroups
    }

    private func load() {
        viewModel.load()
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Account Groups",
            systemImage: "folder",
            description: Text("Create account groups and accounts in Settings.")
        )
    }

    @ViewBuilder
    private var accountsSections: some View {
        ForEach(viewModel.orderedGroups) { accountGroup in
            AccountGroupSectionView(
                accountGroup: accountGroup,
                defaultCurrency: CurrencyCode(rawValue: defaultCurrencyRaw) ?? .eur,
                balanceService: makeBalanceService(),
                onAccountTap: { viewModel.didTapAccount($0) },
                orderedAccounts: viewModel.orderedAccounts(in: accountGroup)
            )
        }
    }
}

private struct AccountGroupSectionView: View {
    let accountGroup: AccountGroup
    let defaultCurrency: CurrencyCode
    let balanceService: AccountGroupBalanceServicing
    let onAccountTap: (Account) -> Void
    let orderedAccounts: [Account]

    var body: some View {
        Section {
            if orderedAccounts.isEmpty {
                Text("No accounts in this group")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(orderedAccounts) { account in
                    AccountRowView(account: account, onTap: { onAccountTap(account) })
                }
            }
        } header: {
            AccountGroupHeaderView(
                accountGroup: accountGroup,
                defaultCurrency: defaultCurrency,
                balanceService: balanceService
            )
        }
    }
}

private struct AccountGroupHeaderView: View {
    let accountGroup: AccountGroup
    let defaultCurrency: CurrencyCode
    let balanceService: AccountGroupBalanceServicing
    @State private var summaryText = "Loading..."

    var body: some View {
        HStack {
            Text(accountGroup.name)
            Spacer()
            Text(summaryText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .task(id: taskID) {
            let summary = await balanceService.total(for: accountGroup, in: defaultCurrency, date: nil)
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

#Preview {
    let context = PreviewSupport.makeContext()
    let repository = PreviewSupport.makeRepository(context: context)
    let viewModel = AccountsViewModel(repository: repository)

    return AccountsView(
        viewModel: viewModel,
        makeBalanceService: { PreviewSupport.makeBalanceService() },
        makeNewTransactionView: { _, _, _ in AnyView(EmptyView()) }
    )
}
