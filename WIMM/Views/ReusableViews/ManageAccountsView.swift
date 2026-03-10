import SwiftUI

struct ManageAccountsView: View {
    @ObservedObject var viewModel: ManageAccountsViewModel
    let makeRepository: () -> FinanceRepositorying
    let makeAddAccountView: () -> AnyView

    @State private var showAdd = false
    @State private var renamingGroup: AccountGroup?
    @State private var editingAccount: Account?
    @State private var deleteAlertMessage: String?

    var body: some View {
        List {
            accountGroupOrderSection
            accountsSections
        }
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", systemImage: "plus") {
                    showAdd = true
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            makeAddAccountView()
        }
        .sheet(item: $editingAccount) { account in
            EditAccountView(
                viewModel: EditAccountViewModel(
                    account: account,
                    canEditStructure: viewModel.canEditAccountStructure(account)
                ),
                orderedGroups: viewModel.orderedGroups,
                canEditStructure: viewModel.canEditAccountStructure(account)
            ) { payload in
                guard let targetGroup = viewModel.accountGroups.first(where: { $0.id == payload.groupID }) else { return }
                viewModel.updateAccount(
                    account,
                    name: payload.name,
                    iconName: payload.iconName,
                    primaryCurrency: payload.primaryCurrency,
                    enabledCurrencies: Array(payload.enabledCurrencies),
                    accountGroup: targetGroup,
                    using: makeRepository()
                )
                load()
            }
        }
        .sheet(item: $renamingGroup) { group in
            RenameEntityView(
                title: "Rename Account Group",
                onSave: { newName in
                    viewModel.renameGroup(group, to: newName, using: makeRepository())
                    load()
                },
                viewModel: RenameEntityViewModel(initialName: group.name)
            )
        }
        .onAppear(perform: load)
        .onChange(of: showAdd) { _, isPresented in
            if !isPresented { load() }
        }
        .alert("Cannot Delete", isPresented: Binding(
            get: { deleteAlertMessage != nil },
            set: { isPresented in
                if !isPresented { deleteAlertMessage = nil }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteAlertMessage ?? "")
        }
    }

    @ViewBuilder
    private var accountGroupOrderSection: some View {
        Section("Account Group Order") {
            ForEach(viewModel.orderedGroups) { group in
                AccountGroupRowView(group: group) {
                    renamingGroup = group
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) {
                        viewModel.deleteGroup(group, using: makeRepository())
                        load()
                    }
                }
                .swipeActions(edge: .leading) {
                    Button("Rename") {
                        renamingGroup = group
                    }
                    .tint(.blue)
                }
            }
            .onMove { source, destination in
                viewModel.moveGroups(from: source, to: destination, current: viewModel.accountGroups, using: makeRepository())
                load()
            }
        }
    }

    @ViewBuilder
    private var accountsSections: some View {
        ForEach(viewModel.orderedGroups) { group in
            Section(group.name) {
                ForEach(viewModel.accounts(in: group)) { account in
                    AccountRowView(account: account, onTap: {
                        editingAccount = account
                    })
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Delete", role: .destructive) {
                            if let reason = viewModel.deleteAccountBlockedReason(account) {
                                deleteAlertMessage = reason
                            } else {
                                viewModel.deleteAccount(account, using: makeRepository())
                                load()
                            }
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button("Edit") {
                            editingAccount = account
                        }
                        .tint(.blue)
                    }
                }
                .onMove { source, destination in
                    viewModel.moveAccounts(in: group, source: source, destination: destination, using: makeRepository())
                    load()
                }
            }
        }
    }

    private func load() {
        viewModel.load(using: makeRepository())
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let repository = PreviewSupport.makeRepository(context: context)
    let viewModel = ManageAccountsViewModel()
    viewModel.load(using: repository)

    return NavigationStack {
        ManageAccountsView(
            viewModel: viewModel,
            makeRepository: { repository },
            makeAddAccountView: { AnyView(EmptyView()) }
        )
    }
}
