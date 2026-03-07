import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Query(sort: [SortDescriptor(\Category.name)])
    private var categories: [Category]

    @StateObject private var viewModel = CategoriesViewModel()

    var body: some View {
        NavigationStack {
            List {
                if viewModel.expenseCategories.isEmpty {
                    ContentUnavailableView(
                        "No Expense Categories",
                        systemImage: "tray",
                        description: Text("Create expense categories in Settings.")
                    )
                } else {
                    ForEach(viewModel.expenseCategories) { category in
                        HStack {
                            Text(category.name)
                            Spacer()
                            Text(viewModel.expenseForCurrentMonth(category))
                                .foregroundStyle(.red)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.didTapCategory(category)
                        }
                    }
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New", systemImage: "plus") {
                        viewModel.didTapNew()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showNewTransaction) {
                NewTransactionView(defaultMode: .expense, preselectedCategoryID: viewModel.preselectedCategoryID)
            }
            .task(id: categoriesSyncKey) {
                viewModel.update(categories: categories)
            }
        }
    }

    private var categoriesSyncKey: String {
        categories
            .map { "\($0.id.uuidString):\($0.name):\($0.kind.rawValue)" }
            .sorted()
            .joined(separator: "|")
    }
}
