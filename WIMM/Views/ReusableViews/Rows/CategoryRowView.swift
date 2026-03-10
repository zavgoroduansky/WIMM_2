import SwiftUI

struct CategoryRowView: View {
    let category: Category
    let onTap: () -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(CategoryColorPalette.color(hex: category.colorHex))
                .frame(width: 10, height: 10)
            Text(category.name)
            Spacer()
            Image(systemName: "pencil")
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    let category = Category(name: "Food", kind: .expense, colorHex: CategoryColorPalette.defaultHex)
    return CategoryRowView(category: category, onTap: {})
}
