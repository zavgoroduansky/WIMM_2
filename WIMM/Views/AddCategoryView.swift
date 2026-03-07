import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel = AddCategoryViewModel()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Category name", text: $viewModel.name)
                Picker("Type", selection: $viewModel.kind) {
                    ForEach(CategoryKind.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
            }
            .navigationTitle("New Category")
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
        }
    }
}
