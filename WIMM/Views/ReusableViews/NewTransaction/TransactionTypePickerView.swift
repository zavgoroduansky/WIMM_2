import SwiftUI

struct TransactionTypePickerView: View {
    @Binding var mode: NewTransactionViewModel.TransactionMode

    var body: some View {
        Picker("Type", selection: $mode) {
            ForEach(NewTransactionViewModel.TransactionMode.allCases) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    TransactionTypePickerView(mode: .constant(.expense))
}
