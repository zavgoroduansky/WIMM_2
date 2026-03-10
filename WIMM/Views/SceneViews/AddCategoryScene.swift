import SwiftUI
import SwiftData

struct AddCategoryScene: View {
    let modelContext: ModelContext
    let dependencies: AppDependencies
    let initialKind: CategoryKind

    @StateObject private var viewModel: AddCategoryViewModel

    init(
        modelContext: ModelContext,
        dependencies: AppDependencies,
        initialKind: CategoryKind = .expense
    ) {
        self.modelContext = modelContext
        self.dependencies = dependencies
        self.initialKind = initialKind
        _viewModel = StateObject(
            wrappedValue: dependencies.makeAddCategoryViewModel(initialKind: initialKind)
        )
    }

    var body: some View {
        AddCategoryView(
            viewModel: viewModel,
            makeRepository: { dependencies.makeFinanceRepository(modelContext: modelContext) }
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let dependencies = PreviewSupport.makeDependencies()
    return AddCategoryScene(modelContext: context, dependencies: dependencies, initialKind: .expense)
}
