import SwiftUI
import SwiftData

struct ManageCategoriesScene: View {
    let dependencies: AppDependencies

    @ObservedObject private var viewModel: ManageCategoriesViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        guard let viewModel = dependencies.manageCategoriesViewModel else {
            fatalError("AppDependencies not configured.")
        }
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        ManageCategoriesView(
            viewModel: viewModel,
            makeAddCategoryView: { kind in
                AnyView(AddCategoryScene(dependencies: dependencies, initialKind: kind))
            }
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let dependencies = PreviewSupport.makeDependencies()
    dependencies.configure(modelContext: context)
    return ManageCategoriesScene(dependencies: dependencies)
}
