import SwiftUI
import SwiftData

struct ReportsScene: View {
    let dependencies: AppDependencies

    @ObservedObject private var viewModel: ReportsViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        guard let viewModel = dependencies.reportsViewModel else {
            fatalError("AppDependencies not configured.")
        }
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        ReportsView(
            viewModel: viewModel
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let dependencies = PreviewSupport.makeDependencies()
    dependencies.configure(modelContext: context)
    return ReportsScene(dependencies: dependencies)
}
