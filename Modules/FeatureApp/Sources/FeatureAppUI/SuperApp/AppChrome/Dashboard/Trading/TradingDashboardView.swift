// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import BlockchainComponentLibrary
import BlockchainNamespace
import BlockchainUI
import ComposableArchitecture
import DIKit
import FeatureAnnouncementsDomain
import FeatureAnnouncementsUI
import FeatureAppDomain
import FeatureCoinUI
import FeatureDashboardUI
import FeatureTopMoversCryptoUI
import FeatureTransactionUI
import Localization
import MoneyKit
import SwiftUI

@available(iOS 15, *)
struct TradingDashboardView: View {
    @BlockchainApp var app

    let store: StoreOf<TradingDashboard>

    @State private var scrollOffset: CGPoint = .zero
    @State private var isBlocked = false

    struct ViewState: Equatable {
        let actions: FrequentActions
        let balance: BalanceInfo?
        let getStartedBuyCryptoAmmounts: [TradingGetStartedAmmountValue]
        var isZeroBalance: Bool { balance?.balance.isZero ?? false }
        var isBalanceLoaded: Bool { balance != nil }
        init(state: TradingDashboard.State) {
            self.actions = state.frequentActions
            self.balance = state.tradingBalance
            self.getStartedBuyCryptoAmmounts = state.getStartedBuyCryptoAmmounts
        }
    }

    init(store: StoreOf<TradingDashboard>) {
        self.store = store
    }

    var body: some View {
        WithViewStore(
            store,
            observe: ViewState.init
        ) { viewStore in
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.padding4) {
                    DashboardMainBalanceView(
                        info: .constant(viewStore.balance),
                        isPercentageHidden: viewStore.isZeroBalance
                    )
                    .padding([.top], Spacing.padding3)

                    FrequentActionsView(
                        actions: !viewStore.isBalanceLoaded || viewStore.isZeroBalance
                        ? viewStore.actions.zeroBalance
                        : viewStore.actions.withBalance,
                        topPadding: viewStore.isZeroBalance ? 0 : Spacing.padding3
                    )

                    FeatureAnnouncementsView(
                        store: store.scope(
                            state: \.announcementsState,
                            action: TradingDashboard.Action.announcementsAction
                        )
                    )

                    if isBlocked {
                        blockedView
                    }

                    if viewStore.isZeroBalance {
                        TradingDashboardToGetStartedBuyView(
                            getStartedBuyCryptoAmmounts: .constant(viewStore.getStartedBuyCryptoAmmounts)
                        )
                        .padding([.horizontal, .bottom], Spacing.padding2)
                    } else {
                        DashboardAssetSectionView(
                            store: store.scope(
                                state: \.assetsState,
                                action: TradingDashboard.Action.assetsAction
                            )
                        )

                        RecurringBuySection()

                        TopMoversSectionView(
                            store: store.scope(state: \.topMoversState, action: TradingDashboard.Action.topMoversAction)
                        )
                        .padding(.horizontal, Spacing.padding2)

                        DashboardActivitySectionView(
                            store: store.scope(state: \.activityState, action: TradingDashboard.Action.activityAction)
                        )

                        DashboardReferralView()

                        NewsSectionView(api: blockchain.api.news.all)
                    }

                    DashboardHelpSectionView()
                }
                .scrollOffset($scrollOffset)
                .task {
                    await viewStore.send(.prepare).finish()
                }
                .padding(.bottom, 72.pt)
                .frame(maxWidth: .infinity)
            }
            .superAppNavigationBar(
                leading: { [app] in dashboardLeadingItem(app: app) },
                title: {
                    if let balance = viewStore.balance?.balance {
                        balance.typography(.body2)
                            .foregroundColor(.semantic.title)
                    }
                },
                trailing: { [app] in dashboardTrailingItem(app: app) },
                titleShouldFollowScroll: true,
                titleExtraOffset: Spacing.padding3,
                scrollOffset: $scrollOffset.y
            )
            .background(Color.semantic.light.ignoresSafeArea(edges: .bottom))
            .bindings {
                subscribe($isBlocked, to: blockchain.user.is.blocked)
            }
        }
    }

    private typealias L10n = LocalizationConstants.SuperApp.Dashboard.GetStarted.Trading
    var blockedView: some View {
        AlertCard(
            title: L10n.blockedTitle,
            message: L10n.blockedMessage,
            variant: .error,
            isBordered: true,
            footer: {
                HStack {
                    SmallSecondaryButton(
                        title: L10n.blockedContactSupport,
                        action: {
                            $app.post(event: blockchain.ux.dashboard.trading.is.blocked.contact.support.paragraph.button.primary.tap)
                        }
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        )
        .padding(.horizontal)
        .onAppear {
            $app.post(event: blockchain.ux.dashboard.trading.is.blocked)
        }
        .batch {
            set(blockchain.ux.dashboard.trading.is.blocked.contact.support.paragraph.button.primary.tap.then.emit, to: blockchain.ux.customer.support.show.messenger)
        }
    }
}

struct TradingDashboardToGetStartedBuyView: View {
    private typealias L10n = LocalizationConstants.SuperApp.Dashboard.GetStarted.Trading
    @Binding var getStartedBuyCryptoAmmounts: [TradingGetStartedAmmountValue]
    @BlockchainApp var app

    var body: some View {
        ZStack {
            Color.semantic.background
            VStack(spacing: Spacing.padding3) {
                Image("buy_btc_icon")
                Text(L10n.toGetStartedTitle)
                    .typography(.title3)
                    .foregroundColor(.semantic.title)
                    .multilineTextAlignment(.center)
                    HStack(spacing: Spacing.padding1) {
                        Group {
                            ForEach(getStartedBuyCryptoAmmounts, id: \.self) { amount in
                                SmallSecondaryButton(
                                    title: amount.valueToDisplay,
                                    maxWidth: true
                                ) {
                                    app.state.set(
                                        blockchain.ux.transaction["buy"].enter.amount.default.input.amount,
                                        to: amount.valueToPreselectOnBuy
                                    )

                                    app.post(
                                        event: blockchain.ux.dashboard.empty.buy.bitcoin[amount.valueToDisplay].paragraph.row.tap
                                    )
                                }
                                .batch {
                                    set(
                                        blockchain.ux.dashboard.empty.buy.bitcoin[amount.valueToDisplay].paragraph.row.event.select.then.emit,
                                        to: blockchain.ux.asset["BTC"].buy
                                    )
                                }
                                .frame(height: 33)
                            }

                            SmallSecondaryButton(
                                title: L10n.toGetStartedBuyOtherAmountButtonTitle,
                                maxWidth: true
                            ) {

                                app.post(
                                    event: blockchain.ux.dashboard.empty.buy.bitcoin["other"].paragraph.row.tap
                                )
                            }
                            .batch {
                                set(
                                    blockchain.ux.dashboard.empty.buy.bitcoin["other"].paragraph.row.event.select.then.emit,
                                    to: blockchain.ux.asset["BTC"].buy
                                )
                            }
                            .pillButtonSize(.standard)
                            .frame(height: 33)
                        }
                    }
                    .batch {
                        set(blockchain.ux.dashboard.empty.buy.other.paragraph.row.event.select.then.emit, to: blockchain.ux.frequent.action.buy)
                    }
                    .frame(maxWidth: .infinity)

                MinimalButton(
                    title: L10n.toGetStartedBuyOtherCryptoButtonTitle,
                    action: { [app] in
                        app.post(event: blockchain.ux.dashboard.empty.buy.other.paragraph.row.tap)
                    }
                )
            }
            .padding([.vertical], Spacing.padding3)
            .padding([.horizontal], Spacing.padding2)
        }
        .cornerRadius(16.0, corners: .allCorners)
    }
}

@available(iOS 15, *)
struct DashboardMainBalanceView: View {
    @Binding var info: BalanceInfo?
    var isPercentageHidden: Bool

    /// default values are for redacted placeholder
    var body: some View {
        if let info {
            MoneyValueHeaderView(
                title: info.balance,
                subtitle: {
                    if !isPercentageHidden, let change = info.change, change.isNotZero {
                        HStack(spacing: Spacing.padding1) {
                            Text(info.marketArrow)
                            change
                            Text(info.changePercentageTitle)
                        }
                        .typography(.paragraph2)
                        .foregroundColor(info.foregroundColor)
                    }
                }
            )
        } else {
            MoneyValueHeaderView(
                title: .create(major: 100.00, currency: .fiat(.USD)),
                subtitle: { Text("↓ $10.50 (0.15%)") }
            )
            .redacted(reason: .placeholder)
        }
    }
}

@available(iOS 15.0, *)
extension BalanceInfo {

    var foregroundColor: Color {
        guard let change, change.isNotZero else {
            return .semantic.body
        }
        return change.isPositive ? .semantic.success : .semantic.pinkHighlight
    }

    var changePercentageTitle: String {
        guard let changePercentageValue else { return "0%" }
        return "(\(changePercentageValue.formatted(.percent.precision(.fractionLength(2)))))"
    }

    var marketArrow: String {
        guard let change else { return "→" }
        return change.isNegative ? "↓" : "↑"
    }
}

// MARK: Provider

@available(iOS 15, *)
func provideTradingDashboard(
    tab: Tab,
    store: StoreOf<DashboardContent>
) -> some View {
    TradingDashboardView(
        store: store.scope(
            state: \.tradingState.home,
            action: DashboardContent.Action.tradingHome
        )
    )
    .tag(tab.ref)
    .id(tab.ref.description)
    .accessibilityIdentifier(tab.ref.description)
}
