import SwiftUI

struct CategorySummaryRowView: View {
    let categoryName: String
    let amountText: String
    let progress: Double
    let colorHex: String?
    let onTap: () -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(CategoryColorPalette.color(hex: colorHex))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 4) {
                Text(categoryName)
                GeometryReader { proxy in
                    Rectangle()
                        .fill(CategoryColorPalette.color(hex: CategoryColorPalette.defaultHex))
                        .frame(
                            width: proxy.size.width * min(max(progress, 0), 1),
                            height: 3
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 3)
            }
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
        progress: 0.33,
        colorHex: CategoryColorPalette.defaultHex,
        onTap: {}
    )
}
