import SwiftUI
import SwiftData

struct AddCategoryScene: View {
    let dependencies: AppDependencies
    let initialKind: CategoryKind

    @StateObject private var viewModel: AddCategoryViewModel

    init(
        dependencies: AppDependencies,
        initialKind: CategoryKind = .expense
    ) {
        self.dependencies = dependencies
        self.initialKind = initialKind
        _viewModel = StateObject(
            wrappedValue: dependencies.makeAddCategoryViewModel(initialKind: initialKind)
        )
    }

    var body: some View {
        AddCategoryView(
            viewModel: viewModel
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let dependencies = PreviewSupport.makeDependencies()
    dependencies.configure(modelContext: context)
    return AddCategoryScene(dependencies: dependencies, initialKind: .expense)
}
