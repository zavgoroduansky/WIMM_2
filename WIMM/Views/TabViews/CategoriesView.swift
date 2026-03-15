import SwiftUI
struct CategoriesView: View {
    @ObservedObject var viewModel: CategoriesViewModel
    let makeNewTransactionView: (_ defaultMode: NewTransactionViewModel.TransactionMode, _ preselectedAccountID: UUID?, _ preselectedCategoryID: UUID?) -> AnyView

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
                    let progressByCategory = viewModel.expenseProgressByCategory()
                    ForEach(viewModel.expenseCategories) { category in
                        CategorySummaryRowView(
                            categoryName: category.name,
                            amountText: viewModel.expenseForCurrentMonth(category),
                            progress: progressByCategory[category.id] ?? 0,
                            colorHex: category.colorHex
                        ) {
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
                makeNewTransactionView(.expense, nil, viewModel.preselectedCategoryID)
            }
            .onAppear(perform: load)
            .onChange(of: viewModel.showNewTransaction) { _, isPresented in
                if !isPresented {
                    load()
                }
            }
        }
    }

    private func load() {
        viewModel.load()
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let repository = PreviewSupport.makeRepository(context: context)
    let viewModel = CategoriesViewModel(repository: repository)
    viewModel.load()

    return CategoriesView(
        viewModel: viewModel,
        makeNewTransactionView: { _, _, _ in AnyView(EmptyView()) }
    )
}

#Preview {
    let context = PreviewSupport.makeContext()
    let repository = PreviewSupport.makeRepository(context: context)
    let viewModel = CategoriesViewModel(repository: repository)
    viewModel.load()

    return CategoriesView(
        viewModel: viewModel,
        makeNewTransactionView: { _, _, _ in AnyView(EmptyView()) }
    )
}
