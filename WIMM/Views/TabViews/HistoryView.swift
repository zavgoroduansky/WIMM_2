import SwiftUI
import SwiftData

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    let makeRepository: () -> FinanceRepositorying
    let makeNewTransactionView: (_ defaultMode: NewTransactionViewModel.TransactionMode, _ preselectedAccountID: UUID?, _ preselectedCategoryID: UUID?) -> AnyView

    var body: some View {
        NavigationStack {
            List(viewModel.entries) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.headline)
                        Text(entry.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                        viewModel.delete(entry: entry, using: makeRepository())
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

    private func color(for tone: HistoryViewModel.EntryTone) -> Color {
        switch tone {
        case .income: return .green
        case .expense: return .red
        case .transfer: return .yellow
        }
    }

    private func load() {
        viewModel.load(using: makeRepository())
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let repository = PreviewSupport.makeRepository(context: context)
    let viewModel = HistoryViewModel()
    viewModel.load(using: repository)

    return HistoryView(
        viewModel: viewModel,
        makeRepository: { repository },
        makeNewTransactionView: { _, _, _ in AnyView(EmptyView()) }
    )
}
