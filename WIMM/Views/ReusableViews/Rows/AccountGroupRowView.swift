import SwiftUI

struct AccountGroupRowView: View {
    let group: AccountGroup
    let onTap: () -> Void

    var body: some View {
        HStack {
            Text(group.name)
            Spacer()
            Text("\(group.accounts.count)")
                .foregroundStyle(.secondary)
            Image(systemName: "pencil")
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    let group = AccountGroup(name: "Cash", sortOrder: 0)
    return AccountGroupRowView(group: group, onTap: {})
}
