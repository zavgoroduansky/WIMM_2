import SwiftUI

struct EditAccountView: View {
    struct Payload {
        let name: String
        let iconName: String
        let groupID: UUID
        let enabledCurrencies: Set<CurrencyCode>
        let primaryCurrency: CurrencyCode
    }

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: EditAccountViewModel
    let orderedGroups: [AccountGroup]
    let canEditStructure: Bool
    let onSave: (Payload) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Account name", text: $viewModel.name)

                Picker("Icon", selection: $viewModel.iconName) {
                    ForEach(viewModel.iconOptions, id: \.self) { icon in
                        Label(icon, systemImage: icon).tag(icon)
                    }
                }

                if canEditStructure {
                    Section("Currencies") {
                        ForEach(CurrencyCode.allCases) { currency in
                            Toggle(isOn: Binding(
                                get: { viewModel.selectedCurrencies.contains(currency) },
                                set: { isOn in
                                    viewModel.toggleCurrency(currency, isOn: isOn)
                                }
                            )) {
                                Text("\(currency.displayName) (\(currency.symbol))")
                            }
                        }

                        Picker("Primary currency", selection: $viewModel.primaryCurrency) {
                            ForEach(Array(viewModel.selectedCurrencies).sorted(by: { $0.rawValue < $1.rawValue })) { item in
                                Text("\(item.displayName) (\(item.symbol))").tag(item)
                            }
                        }
                    }

                    Picker("Account group", selection: $viewModel.selectedGroupID) {
                        ForEach(orderedGroups) { group in
                            Text(group.name).tag(group.id)
                        }
                    }
                }
            }
            .navigationTitle("Edit Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            Payload(
                                name: viewModel.name,
                                iconName: viewModel.iconName,
                                groupID: viewModel.selectedGroupID,
                                enabledCurrencies: viewModel.selectedCurrencies,
                                primaryCurrency: viewModel.primaryCurrency
                            )
                        )
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let group = (try? PreviewSupport.makeRepository(context: context).fetchAccountGroups().first) ?? AccountGroup(name: "Group")
    let account = Account(name: "Wallet", primaryCurrency: .eur, enabledCurrencies: [.eur], accountGroup: group)
    let viewModel = EditAccountViewModel(account: account, canEditStructure: true)

    return EditAccountView(
        viewModel: viewModel,
        orderedGroups: [group],
        canEditStructure: true,
        onSave: { _ in }
    )
}
