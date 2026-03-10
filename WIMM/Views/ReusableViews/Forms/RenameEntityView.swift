import SwiftUI

struct RenameEntityView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let onSave: (String) -> Void
    @ObservedObject var viewModel: RenameEntityViewModel

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $viewModel.name)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(viewModel.trimmedName)
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}

#Preview {
    RenameEntityView(
        title: "Rename",
        onSave: { _ in },
        viewModel: RenameEntityViewModel(initialName: "Sample")
    )
}
