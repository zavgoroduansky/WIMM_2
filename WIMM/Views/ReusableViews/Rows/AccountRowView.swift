import SwiftUI

struct AccountRowView: View {
    let account: Account
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Label(account.name, systemImage: account.iconName ?? "wallet.pass")
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                ForEach(account.balancesByCurrency, id: \.currency) { item in
                    Text(Money.format(minor: item.balanceMinor, currency: item.currency))
                        .foregroundStyle(item.balanceMinor < 0 ? .red : .primary)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    let group = AccountGroup(name: "Cash", sortOrder: 0)
    let account = Account(name: "Wallet", primaryCurrency: .eur, enabledCurrencies: [.eur], accountGroup: group)
    return AccountRowView(account: account, onTap: {})
}
