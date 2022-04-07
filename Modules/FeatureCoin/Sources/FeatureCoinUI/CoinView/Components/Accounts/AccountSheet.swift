// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import Collections
import FeatureCoinDomain
import MoneyKit
import SwiftUI
import ToolKit

struct AccountSheet: View {

    @BlockchainApp var app
    @Environment(\.context) var context

    let account: Account.Snapshot
    var isVerified: Bool
    let onClose: () -> Void

    private var isNotVerified: Bool { !isVerified }

    var actions: [Account.Action] {
        account.actions
            .union(account.importantActions)
            .intersection(account.allowedActions)
            .sorted(like: account.allowedActions)
    }

    var maxHeight: Length {
        (85 / actions.count).clamped(to: 8..<11).vh
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                account.accountType.icon
                    .accentColor(account.color)
                    .frame(maxHeight: 24.pt)
                Text(account.name)
                    .typography(.body2)
                    .foregroundColor(.semantic.title)
                Spacer()
                IconButton(icon: Icon.closev2.circle(), action: onClose)
                    .frame(width: 24.pt, height: 24.pt)
            }
            .padding([.leading, .trailing])
            BalanceSectionHeader(
                title: account.fiat.displayString,
                subtitle: account.crypto.displayString
            )
            let resolved = isNotVerified && account.isPrivateKey
                ? [.send, .receive, .swap, .sell, .activity]
                : actions
            ForEach(resolved) { action in
                PrimaryDivider()
                if actions.contains(action) {
                    PrimaryRow(
                        title: action.title,
                        subtitle: action.description.interpolating(account.cryptoCurrency.code),
                        leading: {
                            action.icon.circle()
                                .accentColor(account.color)
                                .frame(maxHeight: 24.pt)
                        },
                        action: {
                            app.post(event: action.id[].ref(to: context))
                        }
                    )
                    .accessibility(identifier: action.id(\.id))
                    .frame(maxHeight: maxHeight)
                } else {
                    LockedAccountRow(
                        title: action.title,
                        subtitle: action.description.interpolating(account.cryptoCurrency.code),
                        icon: action.icon.circle()
                    )
                    .accessibility(identifier: action.id(\.id))
                    .frame(maxHeight: maxHeight)
                }
            }
        }
    }
}

extension Account.Snapshot {

    var color: Color {
        cryptoCurrency.color
    }

    var allowedActions: [Account.Action] {
        switch accountType {
        case .interest:
            return [.rewards.withdraw, .rewards.deposit, .rewards.summary, .activity]
        case .privateKey:
            return [.send, .receive, .swap, .sell, .activity]
        case .trading:
            return [.buy, .sell, .swap, .send, .receive, .activity]
        case .exchange:
            return [.exchange.withdraw, .exchange.deposit]
        }
    }

    var importantActions: [Account.Action] {
        switch accountType {
        case .interest:
            return [.rewards.withdraw, .rewards.deposit, .rewards.summary]
        default:
            return []
        }
    }
}

extension CryptoCurrency {

    var color: Color {
        assetModel.spotColor.map(Color.init(hex:)) ?? Color(hex: ERC20Code.spotColor(code: code))
    }
}

struct AccountSheetPreviewProvider: PreviewProvider {
    static var previews: some View {
        AccountSheet(
            account: .preview.trading,
            isVerified: true,
            onClose: {}
        )
    }
}
