import SwiftUI

struct ManageCategoriesView: View {
    enum KindTab: String, CaseIterable, Identifiable {
        case expense
        case income

        var id: String { rawValue }

        var kind: CategoryKind {
            switch self {
            case .expense: return .expense
            case .income: return .income
            }
        }

        var title: String {
            switch self {
            case .expense: return "Expense"
            case .income: return "Income"
            }
        }
    }

    @ObservedObject var viewModel: ManageCategoriesViewModel
    let makeAddCategoryView: (_ initialKind: CategoryKind) -> AnyView

    @State private var showAdd = false
    @State private var editingCategory: Category?
    @State private var selectedTab: KindTab = .expense
    @State private var deleteAlertMessage: String?

    var body: some View {
        List {
            Picker("Type", selection: $selectedTab) {
                ForEach(KindTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            ForEach(visibleCategories) { category in
                CategoryRowView(category: category) {
                    editingCategory = category
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", role: .destructive) {
                        if let reason = viewModel.deleteCategoryBlockedReason(category) {
                            deleteAlertMessage = reason
                        } else {
                            viewModel.deleteCategory(category)
                            load()
                        }
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button("Edit") {
                        editingCategory = category
                    }
                    .tint(.blue)
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", systemImage: "plus") {
                    showAdd = true
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            makeAddCategoryView(selectedTab.kind)
        }
        .sheet(item: $editingCategory) { category in
            EditCategoryView(
                viewModel: EditCategoryViewModel(
                    category: category,
                    canEditKind: viewModel.canEditCategoryKind(category)
                )
            ) { payload in
                viewModel.updateCategory(
                    category,
                    name: payload.name,
                    kind: payload.kind,
                    colorHex: payload.colorHex
                )
                load()
            }
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

    private var visibleCategories: [Category] {
        switch selectedTab {
        case .expense:
            return viewModel.expenseCategories
        case .income:
            return viewModel.incomeCategories
        }
    }

    private func load() {
        viewModel.load()
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let repository = PreviewSupport.makeRepository(context: context)
    let viewModel = ManageCategoriesViewModel(repository: repository)
    viewModel.load()

    return NavigationStack {
        ManageCategoriesView(
            viewModel: viewModel,
            makeAddCategoryView: { _ in AnyView(EmptyView()) }
        )
    }
}
