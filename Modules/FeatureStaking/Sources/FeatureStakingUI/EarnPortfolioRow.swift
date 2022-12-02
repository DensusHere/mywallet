// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Blockchain
import BlockchainUI
import FeatureStakingDomain
import SwiftUI

@MainActor
struct EarnPortfolioRow: View {

    @BlockchainApp var app
    @Environment(\.context) var context

    let id: L & I_blockchain_ux_earn_type_hub_product_asset

    let product: EarnProduct
    let currency: CryptoCurrency

    @State var balance: MoneyValue?
    @State var exchangeRate: MoneyValue?

    var body: some View {
        TableRow(
            leading: {
                AsyncMedia(url: currency.logoURL)
                    .frame(width: 24.pt)
            },
            title: TableRowTitle(currency.name),
            byline: { EarnRowByline(product: product) },
            trailing: {
                VStack(alignment: .trailing) {
                    if let balance {
                        if let exchangeRate {
                            Text(balance.convert(using: exchangeRate).displayString)
                                .typography(.paragraph2)
                                .foregroundColor(.semantic.title)
                        }
                        Text(balance.displayString)
                            .typography(.paragraph1)
                            .foregroundColor(.semantic.text)
                    } else {
                        ProgressView()
                    }
                }
            }
        )
        .background(Color.semantic.background)
        .binding(
            .subscribe($exchangeRate, to: blockchain.api.nabu.gateway.price.crypto[currency.code].fiat.quote.value),
            .subscribe($balance, to: blockchain.user.earn.product.asset.account.balance)
        )
        .batch(
            product == .savings
                ? .set(id.paragraph.row.tap.then.emit, to: blockchain.ux.asset[currency.code].account[product.id(currency)].rewards.summary)
                : .set(id.paragraph.row.tap.then.enter.into, to: blockchain.ux.earn.portfolio.product.asset.summary[].ref(to: context))
        )
        .onTapGesture {
            app.post(event: id.paragraph.row.tap[].ref(to: context), context: context)
        }
    }
}

struct EarnRowByline: View {

    let product: EarnProduct
    @State var rate: Double?

    var body: some View {
        HStack {
            if let rate {
                Text(percentageFormatter.string(from: NSNumber(value: rate)) ?? "0%")
                    .typography(.caption1)
                    .foregroundColor(.semantic.text)
            }
            TagView(text: L10n.rewards.interpolating(product.title))
        }
        .subscribe($rate, to: blockchain.user.earn.product.asset.rates.rate)
    }
}
