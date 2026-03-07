import SwiftUI
import SwiftData

struct AddAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let accountGroups: [AccountGroup]

    @AppStorage("defaultCurrency") private var defaultCurrencyRaw = CurrencyCode.eur.rawValue
    @StateObject private var viewModel = AddAccountViewModel()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Account name", text: $viewModel.name)

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

                Picker("Group source", selection: $viewModel.groupMode) {
                    Text("Existing").tag(AddAccountViewModel.GroupMode.existing)
                    Text("New").tag(AddAccountViewModel.GroupMode.new)
                }
                .pickerStyle(.segmented)

                if viewModel.groupMode == .existing {
                    Picker("Account group", selection: $viewModel.selectedAccountGroupID) {
                        ForEach(viewModel.orderedGroups) { accountGroup in
                            Text(accountGroup.name).tag(Optional(accountGroup.id))
                        }
                    }
                } else {
                    TextField("New account group", text: $viewModel.newGroupName)
                }

                Picker("Icon", selection: $viewModel.iconName) {
                    ForEach(viewModel.iconOptions, id: \.self) { icon in
                        Label(icon, systemImage: icon).tag(icon)
                    }
                }
            }
            .navigationTitle("New Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.save(in: modelContext) {
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .onAppear {
                viewModel.update(accountGroups: accountGroups, defaultCurrencyRaw: defaultCurrencyRaw)
            }
            .onChange(of: accountGroups) { _, newGroups in
                viewModel.update(accountGroups: newGroups, defaultCurrencyRaw: defaultCurrencyRaw)
            }
        }
    }
}
