import SwiftUI

struct CategoryColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedHex: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Select category color")
                    .font(.headline)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(CategoryColorPalette.colors) { paletteColor in
                        Button {
                            selectedHex = paletteColor.hex
                            dismiss()
                        } label: {
                            Circle()
                                .fill(paletteColor.preview)
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Circle()
                                        .stroke(selectedHex == paletteColor.hex ? Color.primary : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(280)])
    }
}

#Preview {
    CategoryColorPickerSheet(selectedHex: .constant(CategoryColorPalette.defaultHex))
}
