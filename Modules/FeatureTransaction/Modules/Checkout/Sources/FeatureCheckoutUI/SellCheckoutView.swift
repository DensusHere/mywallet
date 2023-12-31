import BlockchainUI
import FeatureCheckoutDomain
import SwiftUI

public struct SellCheckoutView<Object: LoadableObject>: View where Object.Output == SellCheckout, Object.Failure == Never {

    @BlockchainApp var app

    @ObservedObject var viewModel: Object
    var confirm: (() -> Void)?

    public init(viewModel: Object, confirm: (() -> Void)? = nil) {
        _viewModel = .init(wrappedValue: viewModel)
        self.confirm = confirm
    }

    public var body: some View {
        AsyncContentView(
            source: viewModel,
            loadingView: Loading(),
            content: { object in Loaded(checkout: object, confirm: confirm) }
        )
        .onAppear {
            $app.post(event: blockchain.ux.transaction.checkout)
        }
    }
}

extension SellCheckoutView {

    public init<P>(
        publisher: P,
        confirm: (() -> Void)? = nil
    ) where P: Publisher, P.Output == SellCheckout, P.Failure == Never, Object == PublishedObject<P, DispatchQueue> {
        self.viewModel = PublishedObject(publisher: publisher)
        self.confirm = confirm
    }

    public init(
        _ checkout: Object.Output,
        confirm: (() -> Void)? = nil
    ) where Object == PublishedObject<Just<SellCheckout>, DispatchQueue> {
        self.init(publisher: Just(checkout), confirm: confirm)
    }
}

extension SellCheckoutView {
    public typealias Loading = SellCheckoutLoadingView
    public typealias Loaded = SellCheckoutLoadedView
}

public struct SellCheckoutLoadingView: View {

    public var body: some View {
        ZStack {
            SellCheckoutLoadedView(checkout: .previewTrading)
                .redacted(reason: .placeholder)
            ProgressView()
        }
    }
}

@MainActor
public struct SellCheckoutLoadedView: View {

    struct Explain {
        let title: String
        let message: String
    }

    @BlockchainApp var app

    var checkout: SellCheckout
    var confirm: (() -> Void)?

    @State private var quote: MoneyValue?
    @State private var remainingTime: TimeInterval = .hour
    @State private var isExternalTradingEnabled: Bool = false

    public init(checkout: SellCheckout, confirm: (() -> Void)? = nil) {
        self.checkout = checkout
        self.confirm = confirm
    }
}

extension SellCheckoutView.Loaded {

    @ViewBuilder public var body: some View {
        VStack(alignment: .center) {
            ScrollView {
                sell()
                if isExternalTradingEnabled {
                    bakktRows()
                    bakktBottomView()
                } else {
                    rows()
                    quoteExpiry()
                    disclaimer()
                }
            }
            .padding(.horizontal)
            Spacer()
            footer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .bindings {
            subscribe($isExternalTradingEnabled, to: blockchain.app.is.external.brokerage)
        }
        .batch {
            set(blockchain.ux.tooltip.entry.paragraph.button.minimal.tap.then.enter.into, to: blockchain.ux.tooltip)
        }
        .background(Color.semantic.light.ignoresSafeArea())
        .primaryNavigation(title: L10n.NavigationTitle.sell)
    }

    func showTooltip(title: String, message: String) {
        $app.post(
            event: blockchain.ux.tooltip.entry.paragraph.button.minimal.tap,
            context: [
                blockchain.ux.tooltip.title: title,
                blockchain.ux.tooltip.body: message,
                blockchain.ui.type.action.then.enter.into.detents: [
                    blockchain.ui.type.action.then.enter.into.detents.automatic.dimension
                ]
            ]
        )
    }

    @ViewBuilder func sell() -> some View {
        VStack(alignment: .center) {
            Text(checkout.quote.fiatValue?.toDisplayString(includeSymbol: true, format: .shortened) ?? "")
                .typography(.title1)
                .foregroundColor(.semantic.title)
            Text(checkout.value.displayString)
                .typography(.body1)
                .foregroundColor(.semantic.body)
        }
        .padding(.vertical)
    }

    @ViewBuilder func rows() -> some View {
        DividedVStack(spacing: 0) {
            TableRow(
                title: {
                    HStack {
                        TableRowTitle(L10n.Label.exchangeRate).foregroundColor(.semantic.body)
                        Icon.questionFilled
                            .micro()
                            .color(.semantic.muted)
                    }
                },
                trailing: {
                    TableRowTitle("\(checkout.exchangeRate.base.displayString) = \(checkout.exchangeRate.quote.displayString)")
                }
            )
            .background(Color.semantic.background)
            .onTapGesture {
                showTooltip(
                    title: L10n.Label.exchangeRate,
                    message: L10n.Label.exchangeRateDisclaimer.interpolating(checkout.exchangeRate.quote.code, checkout.exchangeRate.base.code)
                )
            }
            TableRow(
                title: {
                    TableRowTitle(L10n.Label.from)
                        .foregroundColor(.semantic.body)
                },
                trailing: {
                    TableRowTitle(checkout.value.currency.name)
                }
            )

            TableRow(
                title: {
                    TableRowTitle(L10n.Label.to).foregroundColor(.semantic.body)
                },
                trailing: {
                    TableRowTitle(checkout.quote.currency.name)
                }
            )

            if let networkFee = checkout.networkFee,
               let networkFeeFiatValue = checkout.feeFiatValue
            {
                TableRow(
                    title: {
                        HStack {
                            TableRowTitle(L10n.Label.networkFee)
                                .foregroundColor(.semantic.body)
                            Icon.questionFilled
                                .micro()
                                .color(.semantic.muted)
                        }
                    },
                    trailing: {
                        if networkFeeFiatValue.isZero {
                            TagView(text: L10n.Label.free, variant: .success, size: .large)
                        } else {
                            TableRowTitle(networkFeeFiatValue.displayString)
                        }
                    }
                )
                .background(Color.semantic.background)
                .onTapGesture {
                    showTooltip(
                        title: L10n.Label.networkFee,
                        message: L10n.Label.networkFeeDescription.interpolating(networkFee.code)
                    )
                }
            }

            TableRow(
                title: {
                    TableRowTitle(L10n.Label.total).foregroundColor(.semantic.body)
                },
                trailing: {
                    VStack(alignment: .trailing) {
                        TableRowTitle(checkout.totalValue.displayString)
                    }
                }
            )
        }
        .padding(.vertical, 6.pt)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.semantic.background)
        )
    }

    @ViewBuilder func bakktRows() -> some View {
        DividedVStack(spacing: 0) {
            TableRow(
                title: {
                    HStack {
                        TableRowTitle(L10n.Label.price(checkout.exchangeRate.base.code)).foregroundColor(.semantic.body)
                        Icon.questionFilled
                            .micro().color(.semantic.muted)
                    }
                },
                trailing: {
                    TableRowTitle("~\(checkout.exchangeRate.quote.displayString)")
                }
            )
            .background(Color.semantic.background)
            .onTapGesture {
                showTooltip(
                    title: L10n.Label.exchangeRate,
                    message: L10n.Label.exchangeRateDisclaimer.interpolating(checkout.exchangeRate.quote.code, checkout.exchangeRate.base.code)
                )
            }
            TableRow(
                title: {
                    TableRowTitle(L10n.Label.from)
                        .foregroundColor(.semantic.body)
                },
                trailing: {
                    TableRowTitle(checkout.value.currency.name)
                }
            )

            TableRow(
                title: {
                    TableRowTitle(L10n.Label.to).foregroundColor(.semantic.body)
                },
                trailing: {
                    TableRowTitle(checkout.quote.currency.name)
                }
            )
        }
        .padding(.vertical, 6.pt)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.semantic.background)
        )
    }

    @ViewBuilder func quoteExpiry() -> some View {
        if let expiration = checkout.expiresAt {
            CountdownView(deadline: expiration, remainingTime: $remainingTime)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.semantic.background)
                )
        }
    }

    func disclaimer() -> some View {
        Text(rich: L10n.Label.sellDisclaimer)
            .typography(.caption1)
            .foregroundColor(.semantic.body)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.padding1)
            .padding(.top, Spacing.padding3)
            .onTapGesture {
                $app.post(event: blockchain.ux.transaction.checkout.refund.policy.disclaimer)
            }
            .batch {
                set(blockchain.ux.transaction.checkout.refund.policy.disclaimer.then.launch.url, to: { blockchain.ux.transaction.checkout.refund.policy.disclaimer.url })
            }
    }

    @ViewBuilder func bakktBottomView() -> some View {
        VStack {
            VStack(alignment: .leading) {
                bakktDisclaimer()
                SmallMinimalButton(title: L10n.Button.viewDisclosures) {
                    $app.post(event: blockchain.ux.bakkt.view.disclosures)
                }
                .batch {
                    set(blockchain.ux.bakkt.view.disclosures.then.launch.url, to: "https://bakkt.com/disclosures")
                }
            }

            Image("bakkt-logo", bundle: .componentLibrary)
                .foregroundColor(.semantic.title)
                .padding(.top, Spacing.padding2)
        }
    }

    @ViewBuilder
    func bakktDisclaimer() -> some View {
        let label = L10n.Label.sellDisclaimerBakkt(
            amount: checkout.value.toDisplayString(includeSymbol: true),
            asset: checkout.value.currencyType.displayCode
        )

        Text(rich: label)
            .typography(.caption1)
            .foregroundColor(.semantic.body)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, Spacing.padding1)
            .padding(.top, Spacing.padding3)
            .onTapGesture {
                $app.post(event: blockchain.ux.bakkt.authorization)
            }
            .batch {
                set(blockchain.ux.bakkt.authorization.then.launch.url, to: { blockchain.ux.bakkt.authorization.url })
            }
    }

    func footer() -> some View {
        VStack(spacing: 0) {
            PrimaryButton(title: L10n.Button.confirmSell) {
                confirm?()
                $app.post(event: blockchain.ux.transaction.checkout.confirmed)
            }
            .disabled(remainingTime < 5)
            .padding()
            .background(Color.clear)
        }
    }
}

// MARK: Preview

struct SellCheckoutView_Previews: PreviewProvider {

    static var previews: some View {

        SellCheckoutLoadingView()
            .app(App.preview)
            .context([blockchain.ux.transaction.id: "sell"])
            .previewDisplayName("Loading")

        SellCheckoutLoadedView(checkout: .previewDeFi)
            .app(App.preview)
            .context([blockchain.ux.transaction.id: "sell"])
            .previewDisplayName("Private Key Sell")

        SellCheckoutLoadedView(checkout: .previewTrading)
            .app(App.preview)
            .context([blockchain.ux.transaction.id: "sell"])
            .previewDisplayName("Trading Sell")
    }
}
