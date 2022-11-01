//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import ComposableArchitecture
import ComposableNavigation
import DIKit
import ErrorsUI
import FeatureAppUI
import FeatureInterestUI
import Localization
import MoneyKit
import SwiftUI

struct Tab: Hashable, Identifiable, Codable {
    var id: AnyHashable { tag }
    var tag: Tag.Reference
    var name: String
    var ux: UX.Dialog?
    var url: URL?
    var icon: Icon
    var unselectedIcon: Icon?
}

extension Tab: CustomStringConvertible {
    var description: String { tag.string }
}

extension Tab {

    var ref: Tag.Reference { tag }

    // swiftlint:disable force_try

    // OA Add support for pathing directly into a reference
    // e.g. ref.descendant(blockchain.ux.type.story, \.entry)
    func entry() -> Tag.Reference {
        try! ref.tag.as(blockchain.ux.type.story).entry[].ref(to: ref.context)
    }
}

let _app = app
struct RootView: View {
    var app: AppProtocol = _app

    let store: Store<RootViewState, RootViewAction>
    @ObservedObject private var viewStore: ViewStore<RootViewState, RootViewAction>

    init(store: Store<RootViewState, RootViewAction>) {
        self.store = store
        viewStore = ViewStore(store)
        setupApperance()
    }

    func setupApperance() {
        UITabBar.appearance().backgroundImage = UIImage()
        UITabBar.appearance().barTintColor = .white
        UITabBar.appearance().tintColor = .brandPrimary
    }

    var body: some View {
        TabView(selection: viewStore.binding(\.$tab)) {
            tabs(in: viewStore)
        }
        .overlay(overlay, alignment: .bottom)
        .bottomSheet(
            isPresented: viewStore.binding(\.$isAppModeSwitcherPresented).animation(.spring()),
            content: {
                IfLetStore(
                    store.scope(
                        state: \.appModeSwitcherState,
                        action: RootViewAction.appModeSwitcherAction
                    ),
                    then: { store in
                        AppModeSwitcherView(store: store)
                    }
                )
            }
        )
        .bottomSheet(isPresented: viewStore.binding(\.$fab.isOn).animation(.spring())) {
            IfLetStore(store.scope(state: \.fab.data)) { store in
                WithViewStore(store) { viewStore in
                    FrequentActionView(
                        list: viewStore.list,
                        buttons: viewStore.buttons
                    )
                }
            }
        }
        .onReceive(app.on(blockchain.ux.home.tab.select)) { event in
            do {
                try viewStore.send(.tab(event.reference.context.decode(blockchain.ux.home.tab.id)))
            } catch {
                app.post(error: error)
            }
        }
        .onChange(of: viewStore.tab) { tab in
            app.post(event: tab.tag)
        }
        .onAppear {
            app.post(event: blockchain.ux.home)
            app.post(event: viewStore.tab.tag)
        }
        .onAppear {
            viewStore.send(.onAppear)
        }
        .onDisappear {
            viewStore.send(.onDisappear)
        }
        .navigationRoute(in: store)
        .app(app)
    }

    @ViewBuilder var overlay: some View {
        floatingButtonOverlay
    }

    var floatingButtonOverlay: some View {
        FloatingActionButton(isOn: viewStore.binding(\.$fab.isOn).animation(.spring()))
            .identity(blockchain.ux.frequent.action)
            .background(
                Circle()
                    .fill(Color.semantic.background)
                    .padding(Spacing.padding1)
            )
            .pulse(enabled: viewStore.fab.animate, inset: 8)
            .padding([.leading, .trailing], 24.pt)
            .offset(y: 6.pt)
            .contentShape(Rectangle())
            .background(Color.white.invisible())
            .if(viewStore.hideFAB, then: { view in view.hidden() })
    }

    func tabs(in viewStore: ViewStore<RootViewState, RootViewAction>) -> some View {
        ForEach(viewStore.tabs ?? []) { tab in
            tabItem(tab) {
                switch tab.tag {
                case blockchain.ux.user.portfolio:
                    PortfolioView(store: store.stateless)
                case blockchain.ux.prices:
                    PricesView(store: store.stateless)
                case blockchain.ux.frequent.action:
                    Icon.blockchain
                        .frame(width: 32.pt, height: 32.pt)
                case blockchain.ux.buy_and_sell:
                    BuySellView(selectedSegment: viewStore.binding(\.$buyAndSell.segment))
                case blockchain.ux.user.rewards:
                    RewardsView()
                case blockchain.ux.user.activity:
                    ActivityView()
                case blockchain.ux.maintenance:
                    maintenance(tab)
                case blockchain.ux.nft.collection:
                    AssetListViewController()
                case blockchain.ux.web:
                    if let url = tab.url {
                        WebView(url: url)
                    } else {
                        maintenance(tab)
                    }
                default:
#if DEBUG
                    fatalError("Unhandled \(tab)")
#else
                    maintenance(tab)
#endif
                }
            }
        }
    }

    func bottomViewItems(for viewStore: ViewStore<RootViewState, RootViewAction>) -> [BottomBarItem<Tag.Reference>] {
        let tabs = viewStore.tabs ?? []
        return tabs
            .map {
                BottomBarItem(
                    id: $0.ref,
                    selectedIcon: $0.icon.renderingMode(.original),
                    unselectedIcon: $0.unselectedIcon?.renderingMode(.original) ?? Icon.hardware,
                    title: $0.name.localized()
                )
            }
    }

    @ViewBuilder func maintenance(_ tab: Tab) -> some View {
        if let ux = tab.ux {
            ErrorView(
                ux: UX.Error(nabu: ux),
                dismiss: {}
            )
        }
    }

    @ViewBuilder private func tabItem(
        _ tab: Tab,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        PrimaryNavigationView {
            content()
                .primaryNavigation(
                    leading: leadingViews,
                    title: viewStore.appSwitcherEnabled ? "" : tab.name.localized(),
                    trailing: trailingViews
                )
        }
        .tabItem {
            Label(
                title: {
                    Text(tab.name.localized())
                        .typography(.micro)
                },
                icon: { tab.icon.image }
            )
            .identity(tab.entry())
        }
        .tag(tab.ref)
        .identity(tab.ref)
    }

    @ViewBuilder func trailingViews() -> some View {
        Group {
            referrals()
                .if(!viewStore.referralState.isVisible, then: { view in view.hidden() })

                    QR()

                    if viewStore.appSwitcherEnabled
            {
                    account()
                }
        }
    }

    @ViewBuilder func leadingViews() -> some View {
        Group {
            if viewStore.appSwitcherEnabled, let appMode = viewStore.appMode {
                appModeSwitcher(with: appMode)
            } else {
                account()
            }
        }
    }

    @ViewBuilder func referrals() -> some View {
        let onReferralTapAction: () -> Void = {
            viewStore.send(.onReferralTap)
        }

        IconButton(icon: Icon.giftboxHighlighted.renderingMode(.original), action: onReferralTapAction)
            .if(
                !viewStore.referralState.isHighlighted,
                then: { view in view.update(icon: Icon.giftbox) }
            )
                .identity(blockchain.ux.referral.entry)
    }

    @ViewBuilder func appModeSwitcher(with appMode: AppMode) -> some View {
        AppModeSwitcherButton(
            appMode: appMode,
            action: {
                viewStore.send(.onAppModeSwitcherTapped)
            }
        )
        .if(!viewStore.appModeSeen, then: { $0.highlighted() })
            .identity(blockchain.ux.switcher.entry)
    }

    @ViewBuilder func QR() -> some View {
        WithViewStore(store.stateless) { viewStore in
            IconButton(icon: .qrCode) {
                viewStore.send(.enter(into: .QR, context: .none))
            }
            .identity(blockchain.ux.scan.QR.entry)
        }
    }

    @ViewBuilder func account() -> some View {
        WithViewStore(store) { viewStore in
            IconButton(icon: .user) {
                viewStore.send(.enter(into: .account, context: .none))
            }
            .overlay(Badge(count: viewStore.unreadSupportMessageCount))
            .identity(blockchain.ux.user.account.entry)
        }
    }
}

// swiftlint:disable empty_count
struct Badge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            ZStack(alignment: .topTrailing) {
                Color.clear
                Text(count.description)
                    .typography(.micro.bold())
                    .foregroundColor(.semantic.light)
                    .padding(4)
                    .background(Color.semantic.error)
                    .clipShape(Circle())
                    .alignmentGuide(.top) { $0[.bottom] }
                    .alignmentGuide(.trailing) { $0[.trailing] - $0.width * 0.2 }
            }
        }
    }
}

extension Color {

    /// A workaround to ensure taps are not passed through to the view behind
    func invisible() -> Color {
        opacity(0.001)
    }
}

extension View {
    @ViewBuilder
    func identity(_ tag: Tag.Event, in context: Tag.Context = [:]) -> some View {
        id(tag.description)
            .accessibility(identifier: tag.description)
    }
}
