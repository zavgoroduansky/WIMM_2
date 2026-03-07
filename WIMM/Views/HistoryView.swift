import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse)])
    private var transactions: [Transaction]

    @StateObject private var viewModel = HistoryViewModel()

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
                NewTransactionView(defaultMode: .expense)
            }
            .task(id: transactionsSyncKey) {
                viewModel.update(transactions: transactions)
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

    private var transactionsSyncKey: String {
        transactions
            .map { "\($0.id.uuidString):\($0.date.timeIntervalSince1970)" }
            .joined(separator: "|")
    }
}
