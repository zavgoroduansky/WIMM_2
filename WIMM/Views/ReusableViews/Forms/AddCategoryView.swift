import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: AddCategoryViewModel
    let makeRepository: () -> FinanceRepositorying
    @State private var showColorPicker = false

    var body: some View {
        NavigationStack {
            Form {
                TextField("Category name", text: $viewModel.name)
                Picker("Type", selection: $viewModel.kind) {
                    ForEach(CategoryKind.allCases) { item in
                        Text(item.title).tag(item)
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
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.save(using: makeRepository()) {
                            dismiss()
                        }
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
    let context = PreviewSupport.makeContext()
    let repository = PreviewSupport.makeRepository(context: context)
    let viewModel = AddCategoryViewModel()

    return AddCategoryView(
        viewModel: viewModel,
        makeRepository: { repository }
    )
}
