import SwiftUI
import SwiftData

struct ReportsScene: View {
    let modelContext: ModelContext
    let dependencies: AppDependencies

    @StateObject private var viewModel: ReportsViewModel

    init(modelContext: ModelContext, dependencies: AppDependencies) {
        self.modelContext = modelContext
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: dependencies.makeReportsViewModel())
    }

    var body: some View {
        ReportsView(
            viewModel: viewModel,
            makeRepository: { dependencies.makeFinanceRepository(modelContext: modelContext) }
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let dependencies = PreviewSupport.makeDependencies()
    return ReportsScene(modelContext: context, dependencies: dependencies)
}
