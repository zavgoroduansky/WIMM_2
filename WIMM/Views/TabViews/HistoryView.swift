import SwiftUI
struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    let makeNewTransactionView: (_ defaultMode: NewTransactionViewModel.TransactionMode, _ preselectedAccountID: UUID?, _ preselectedCategoryID: UUID?) -> AnyView

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.sections) { section in
                    Section {
                        ForEach(section.entries) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.title)
                                        .font(.headline)
                                    if let note = entry.note, !note.isEmpty {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Text(entry.amountText)
                                    .foregroundStyle(color(for: entry.tone))
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button("Delete", role: .destructive) {
                                    viewModel.delete(entry: entry)
                                }
                            }
                        }
                    } header: {
                        Text(viewModel.sectionTitle(for: section.date))
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New", systemImage: "plus") {
                        viewModel.didTapNew()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showNewTransaction) {
                makeNewTransactionView(.expense, nil, nil)
            }
            .onAppear(perform: load)
            .onChange(of: viewModel.showNewTransaction) { _, isPresented in
                if !isPresented {
                    load()
                }
            }
        }
    }

    private func color(for tone: HistoryEntryTone) -> Color {
        switch tone {
        case .income: return .green
        case .expense: return .red
        case .transfer: return .yellow
        }
    }

    private func load() {
        viewModel.load()
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let repository = PreviewSupport.makeRepository(context: context)
    let viewModel = HistoryViewModel(repository: repository, useCase: HistoryUseCase())
    viewModel.load()

    return HistoryView(
        viewModel: viewModel,
        makeNewTransactionView: { _, _, _ in AnyView(EmptyView()) }
    )
}
