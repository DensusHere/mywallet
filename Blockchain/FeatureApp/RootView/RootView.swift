//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import ComposableArchitecture
import ComposableNavigation
import DIKit
import FeatureInterestUI
import Localization
import MoneyKit
import SwiftUI

struct Tab: Hashable, Identifiable, Codable {
    var id: AnyHashable { tag }
    var tag: Tag.Reference
    var name: String
    var title, message: String?
    var url: URL?
    var icon: Icon
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

struct RootView: View {

    @Environment(\.openURL) var openURL

    let store: Store<RootViewState, RootViewAction>

    init(store: Store<RootViewState, RootViewAction>) {
        self.store = store
        setupApperance()
    }

    func setupApperance() {
        UITabBar.appearance().backgroundImage = UIImage()
        UITabBar.appearance().barTintColor = .white
        UITabBar.appearance().tintColor = .brandPrimary
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            Group {
                TabView(selection: viewStore.binding(\.$tab)) {
                    tabs(in: viewStore)
                }
                .overlay(
                    FloatingActionButton(isOn: viewStore.binding(\.$fab.isOn).animation(.spring()))
                        .if(viewStore.hideFAB, then: { view in view.hidden() })
                        .identity(blockchain.ux.frequent.action)
                        .background(
                            Circle()
                                .fill(Color.semantic.background)
                                .padding(8)
                        )
                        .pulse(enabled: viewStore.fab.animate, inset: 8)
                        .padding([.leading, .trailing], 24.pt)
                        .offset(y: 6.pt)
                        .contentShape(Rectangle())
                        .background(Color.white.invisible()),
                    alignment: .bottom
                )
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .bottomSheet(isPresented: viewStore.binding(\.$fab.isOn).animation(.spring())) {
                IfLetStore(store.scope(state: \.fab.data)) { store in
                    WithViewStore(store) { viewStore in
                        FrequentActionView(
                            list: viewStore.list,
                            buttons: viewStore.buttons
                        ) { action in
                            withAnimation {
                                viewStore.send(.frequentAction(action))
                            }
                        }
                    }
                }
            }
            .on(blockchain.ux.home.tab.select) { event in
                try viewStore.send(.tab(event.reference.context.decode(blockchain.ux.home.tab.id)))
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
            .onDisappear {
                viewStore.send(.onDisappear)
            }
        }
        .navigationRoute(in: store)
        .app(Blockchain.app)
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

    func maintenance(_ tab: Tab) -> some View {
        VStack(spacing: Spacing.padding3) {
            tab.icon
                .frame(width: 30.vw)
                .aspectRatio(contentMode: .fit)
            if let title = tab.title {
                Text(title.localized())
                    .typography(.title3)
                    .foregroundColor(.semantic.title)
            }
            if let message = tab.message {
                Text(message.localized())
                    .typography(.body1)
                    .foregroundColor(.semantic.body)
            }
            Spacer()
            if let url = tab.url {
                Button(LocalizationConstants.openWebsite) {
                    openURL(url)
                }
            }
        }
        .multilineTextAlignment(.center)
        .padding()
    }

    @ViewBuilder func tabItem<Content>(
        _ tab: Tab,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Content: View {
        PrimaryNavigationView {
            content()
                .primaryNavigation(
                    leading: account,
                    title: tab.name.localized(),
                    trailing: QR
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

    @ViewBuilder func QR() -> some View {
        WithViewStore(store.stateless) { viewStore in
            IconButton(icon: .qrCode) {
                viewStore.send(.enter(into: .QR, context: .none))
            }
            .identity(blockchain.ux.scan.QR.entry)
        }
    }

    @ViewBuilder func account() -> some View {
        WithViewStore(store.stateless) { viewStore in
            IconButton(icon: .user) {
                viewStore.send(.enter(into: .account, context: .none))
            }
            .identity(blockchain.ux.user.account.entry)
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