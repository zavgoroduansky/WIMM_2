import SwiftUI
import SwiftData

struct ManageCategoriesScene: View {
    let modelContext: ModelContext
    let dependencies: AppDependencies

    @StateObject private var viewModel: ManageCategoriesViewModel

    init(modelContext: ModelContext, dependencies: AppDependencies) {
        self.modelContext = modelContext
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: dependencies.makeManageCategoriesViewModel())
    }

    var body: some View {
        ManageCategoriesView(
            viewModel: viewModel,
            makeRepository: { dependencies.makeFinanceRepository(modelContext: modelContext) },
            makeAddCategoryView: { kind in
                AnyView(AddCategoryScene(modelContext: modelContext, dependencies: dependencies, initialKind: kind))
            }
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let dependencies = PreviewSupport.makeDependencies()
    return ManageCategoriesScene(modelContext: context, dependencies: dependencies)
}
