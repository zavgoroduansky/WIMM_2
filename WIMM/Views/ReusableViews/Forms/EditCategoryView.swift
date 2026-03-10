import SwiftUI

struct EditCategoryView: View {
    struct Payload {
        let name: String
        let kind: CategoryKind
        let colorHex: String
    }

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: EditCategoryViewModel
    let onSave: (Payload) -> Void
    @State private var showColorPicker = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Category name", text: $viewModel.name)

                if viewModel.canEditKind {
                    Picker("Type", selection: $viewModel.kind) {
                        ForEach(CategoryKind.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                }

                Button {
                    showColorPicker = true
                } label: {
                    HStack {
                        Text("Color")
                        Spacer()
                        Circle()
                            .fill(CategoryColorPalette.color(hex: viewModel.colorHex))
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .navigationTitle("Edit Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(Payload(name: viewModel.name, kind: viewModel.kind, colorHex: viewModel.colorHex))
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .sheet(isPresented: $showColorPicker) {
                CategoryColorPickerSheet(selectedHex: $viewModel.colorHex)
            }
        }
    }
}

#Preview {
    let category = Category(name: "Food", kind: .expense, colorHex: CategoryColorPalette.defaultHex)
    let viewModel = EditCategoryViewModel(category: category, canEditKind: true)

    return EditCategoryView(
        viewModel: viewModel,
        onSave: { _ in }
    )
}
