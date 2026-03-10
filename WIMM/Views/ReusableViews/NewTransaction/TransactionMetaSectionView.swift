import SwiftUI

struct TransactionMetaSectionView: View {
    @Binding var date: Date
    @Binding var note: String

    var body: some View {
        DatePicker("Date", selection: $date, displayedComponents: [.date])
        TextField("Note", text: $note, axis: .vertical)
    }
}

#Preview {
    TransactionMetaSectionView(date: .constant(Date()), note: .constant("Note"))
}
