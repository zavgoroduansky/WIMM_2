import SwiftUI

struct CategorySummaryRowView: View {
    let categoryName: String
    let amountText: String
    let colorHex: String?
    let onTap: () -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(CategoryColorPalette.color(hex: colorHex))
                .frame(width: 10, height: 10)
            Text(categoryName)
            Spacer()
            Text(amountText)
                .foregroundStyle(.primary)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    CategorySummaryRowView(
        categoryName: "Food",
        amountText: "12.50 EUR",
        colorHex: CategoryColorPalette.defaultHex,
        onTap: {}
    )
}
