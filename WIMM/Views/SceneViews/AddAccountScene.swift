import SwiftUI
import SwiftData

struct AddAccountScene: View {
    let modelContext: ModelContext
    let dependencies: AppDependencies

    @StateObject private var viewModel: AddAccountViewModel

    init(modelContext: ModelContext, dependencies: AppDependencies) {
        self.modelContext = modelContext
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: dependencies.makeAddAccountViewModel())
    }

    var body: some View {
        AddAccountView(
            viewModel: viewModel,
            makeRepository: { dependencies.makeFinanceRepository(modelContext: modelContext) }
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let dependencies = PreviewSupport.makeDependencies()
    return AddAccountScene(modelContext: context, dependencies: dependencies)
}
