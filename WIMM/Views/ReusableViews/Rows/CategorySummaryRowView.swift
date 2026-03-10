import SwiftUI

struct CategorySummaryRowView: View {
    let categoryName: String
    let amountText: String
    let onTap: () -> Void

    var body: some View {
        HStack {
            Text(categoryName)
            Spacer()
            Text(amountText)
                .foregroundStyle(.red)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    CategorySummaryRowView(categoryName: "Food", amountText: "12.50 EUR", onTap: {})
}
