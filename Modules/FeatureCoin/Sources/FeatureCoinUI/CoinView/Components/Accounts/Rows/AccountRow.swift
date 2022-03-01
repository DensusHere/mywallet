// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import Combine
import FeatureCoinDomain
import MoneyKit
import SwiftUI

struct AccountRow: View {
    let account: Account
    let assetColor: Color
    let action: () -> Void

    var cryptoValuePublisher: AnyPublisher<MoneyValue, Never>
    @State private var cryptoValue: String = ""

    var fiatValuePublisher: AnyPublisher<MoneyValue, Never>
    @State private var fiatValue: String = ""

    init(
        account: Account,
        assetColor: Color,
        action: @escaping () -> Void
    ) {
        self.account = account
        self.assetColor = assetColor
        self.action = action
        cryptoValuePublisher = account.cryptoBalancePublisher
        fiatValuePublisher = account.fiatBalancePublisher
    }

    var body: some View {
        BalanceRow(
            leadingTitle: account.name,
            leadingDescription: account.accountType.subtitle,
            trailingTitle: fiatValue,
            trailingDescription: cryptoValue,
            trailingDescriptionColor: .semantic.muted,
            leading: {
                account.accountType.icon
                    .accentColor(assetColor)
                    .frame(width: 24)
            }
        )
        .onReceive(cryptoValuePublisher) {
            cryptoValue = $0.displayString
        }
        .onReceive(fiatValuePublisher) {
            fiatValue = $0.displayString
        }
    }
}

extension Account.AccountType {
    var icon: Icon {
        switch self {
        case .exchange:
            return .walletExchange
        case .interest:
            return .interestCircle
        case .privateKey:
            return .private
        case .trading:
            return .trade
        }
    }

    var subtitle: String {
        switch self {
        case .exchange:
            return "Pro Trading"
        case .interest:
            return "Earning 3.5%"
        case .privateKey:
            return "Non-custodial"
        case .trading:
            return "Custodial"
        }
    }
}

// swiftlint:disable type_name
struct AccountRow_PreviewProvider: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 0) {
                PrimaryDivider()

                AccountRow(
                    account: .init(
                        id: "",
                        name: "Private Key Wallet",
                        accountType: .privateKey,
                        cryptoCurrency: .bitcoin,
                        fiatCurrency: .USD,
                        cryptoBalancePublisher: .just(.one(currency: .bitcoin)),
                        fiatBalancePublisher: .just(.one(currency: .USD))
                    ),
                    assetColor: .orange,
                    action: {}
                )

                PrimaryDivider()

                AccountRow(
                    account: .init(
                        id: "",
                        name: "Trading Account",
                        accountType: .trading,
                        cryptoCurrency: .bitcoin,
                        fiatCurrency: .USD,
                        cryptoBalancePublisher: .just(.one(currency: .bitcoin)),
                        fiatBalancePublisher: .just(.one(currency: .USD))
                    ),
                    assetColor: .orange,
                    action: {}
                )

                PrimaryDivider()

                AccountRow(
                    account: .init(
                        id: "",
                        name: "Rewards Account",
                        accountType: .interest,
                        cryptoCurrency: .bitcoin,
                        fiatCurrency: .USD,
                        cryptoBalancePublisher: .just(.one(currency: .bitcoin)),
                        fiatBalancePublisher: .just(.one(currency: .USD))
                    ),
                    assetColor: .orange,
                    action: {}
                )

                PrimaryDivider()

                AccountRow(
                    account: .init(
                        id: "",
                        name: "Exchange Account",
                        accountType: .exchange,
                        cryptoCurrency: .bitcoin,
                        fiatCurrency: .USD,
                        cryptoBalancePublisher: .just(.one(currency: .bitcoin)),
                        fiatBalancePublisher: .just(.one(currency: .USD))
                    ),
                    assetColor: .orange,
                    action: {}
                )

                PrimaryDivider()
            }
        }
    }
}
