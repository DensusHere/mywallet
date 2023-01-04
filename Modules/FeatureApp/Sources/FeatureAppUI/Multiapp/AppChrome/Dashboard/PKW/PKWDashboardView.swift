// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import ComposableArchitecture
import DIKit
import FeatureDashboardUI
import SwiftUI

@available(iOS 15, *)
struct PKWDashboardView: View {
    @BlockchainApp var app

    let store: StoreOf<PKWDashboard>

    @State var scrollOffset: CGFloat = 0
    @StateObject var scrollViewObserver = ScrollViewOffsetObserver()

    struct ViewState: Equatable {
        let actions: FrequentActions
        let balance: DeFiTotalBalanceInfo?
        init(state: PKWDashboard.State) {
            self.actions = state.frequentActions
            self.balance = state.balance
        }
    }

    init(store: StoreOf<PKWDashboard>) {
        self.store = store
    }

    var body: some View {
        WithViewStore(
            store,
            observe: ViewState.init
        ) { viewStore in
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.padding4) {
                    // default value for redacted placeholder
                    Text(viewStore.balance?.formatted ?? "$100.000")
                        .typography(.title1)
                        .foregroundColor(.semantic.title)
                        .padding([.top], Spacing.padding3)
                        .redacted(reason: viewStore.balance == nil ? .placeholder : [])

                    FrequentActionsView(
                        actions: viewStore.actions
                    )
                    DashboardAssetSectionView(store: store.scope(
                        state: \.assetsState,
                        action: PKWDashboard.Action.assetsAction
                    ))

                    DashboardActivitySectionView(
                        store: self.store.scope(state: \.activityState, action: PKWDashboard.Action.activityAction)
                    )
                }
                .findScrollView { scrollView in
                    scrollViewObserver.didScroll = { offset in
                        DispatchQueue.main.async {
                            $scrollOffset.wrappedValue = offset.y
                        }
                    }
                    scrollView.delegate = scrollViewObserver
                }
                .task {
                    await viewStore.send(.fetchBalance).finish()
                }
                .padding(.bottom, 72.pt)
                .frame(maxWidth: .infinity)
            }
            .superAppNavigationBar(
                leading: { [app] in dashboardLeadingItem(app: app) },
                title: {
                    Text(viewStore.balance?.formatted ?? "")
                        .typography(.body2)
                        .foregroundColor(.semantic.title)
                },
                trailing: { [app] in dashboardTrailingItem(app: app) },
                titleShouldFollowScroll: true,
                titleExtraOffset: Spacing.padding3,
                scrollOffset: $scrollOffset
            )
            .background(Color.semantic.light.ignoresSafeArea(edges: .bottom))
        }
    }
}

// MARK: Provider

@available(iOS 15, *)
func provideDefiDashboard(
    tab: Tab,
    store: StoreOf<DashboardContent>
) -> some View {
    PKWDashboardView(
        store: store.scope(
            state: \.defiState.home,
            action: DashboardContent.Action.defiHome
        )
    )
    .tag(tab.ref)
    .id(tab.ref.description)
    .accessibilityIdentifier(tab.ref.description)
}
