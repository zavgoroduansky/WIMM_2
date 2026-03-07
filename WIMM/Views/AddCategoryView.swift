import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var kind: CategoryKind = .expense

    var body: some View {
        NavigationStack {
            Form {
                TextField("Category name", text: $name)
                Picker("Type", selection: $kind) {
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
                        let category = Category(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            kind: kind
                        )
                        modelContext.insert(category)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
