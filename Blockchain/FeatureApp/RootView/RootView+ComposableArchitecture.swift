//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import Combine
import ComposableArchitecture
import ComposableArchitectureExtensions
import ComposableNavigation
import DIKit
import FeatureAppUI
import Localization
import MoneyKit
import SwiftUI
import ToolKit

struct RootViewState: Equatable, NavigationState {

    var route: RouteIntent<RootViewRoute>?

    @BindableState var tab: Tab = .home
    @BindableState var fab: FrequentAction

    @BindableState var buyAndSell: BuyAndSell = .init()
}

extension RootViewState {

    struct BuyAndSell: Equatable {

        var segment: Int = 0
    }

    struct FrequentAction: Equatable {

        var isOn: Bool = false
        var animate: Bool
        var data: Data = .init()

        struct Data: Codable, Equatable {

            var list: [Tag] = [
                blockchain.ux.frequent.action.swap[],
                blockchain.ux.frequent.action.send[],
                blockchain.ux.frequent.action.receive[],
                blockchain.ux.frequent.action.rewards[]
            ]

            var buttons: [Tag] = [
                blockchain.ux.frequent.action.sell[],
                blockchain.ux.frequent.action.buy[]
            ]
        }
    }
}

enum RootViewAction: Equatable, NavigationAction, BindableAction {
    case route(RouteIntent<RootViewRoute>?)
    case tab(Tab)
    case frequentAction(FrequentAction)
    case binding(BindingAction<RootViewState>)
    case onAppear
    case onDisappear
}

enum RootViewRoute: NavigationRoute {

    case account
    case QR
    case coinView(CryptoCurrency)

    @ViewBuilder func destination(in store: Store<RootViewState, RootViewAction>) -> some View {
        switch self {
        case .QR:
            QRCodeScannerView()
                .identity(blockchain.ux.scan.QR)
                .ignoresSafeArea()
        case .account:
            AccountView()
                .identity(blockchain.ux.user.account)
                .ignoresSafeArea(.container, edges: .bottom)
        case .coinView(let currency):
            CoinAdapterView(cryptoCurrency: currency)
                .identity(blockchain.ux.asset)
        }
    }
}

struct RootViewEnvironment: PublishedEnvironment {
    var subject: PassthroughSubject<(state: RootViewState, action: RootViewAction), Never> = .init()
    var app: AppProtocol
}

let rootViewReducer = Reducer<
    RootViewState,
    RootViewAction,
    RootViewEnvironment
> { state, action, environment in
    switch action {
    case .tab(let tab):
        state.tab = tab
        return .none
    case .frequentAction(let action):
        state.fab.isOn = false
        switch action {
        case .buy:
            state.buyAndSell.segment = 0
            state.tab = .buyAndSell
        case .sell:
            state.buyAndSell.segment = 1
            state.tab = .buyAndSell
        default:
            break
        }
        return .none
    case .binding(.set(\.$fab.isOn, true)):
        state.fab.animate = false
        return .none
    case .onAppear:
        return .fireAndForget {
            environment.app.state.set(blockchain.app.is.ready.for.deep_link, to: true)
        }
    case .onDisappear:
        return .fireAndForget {
            environment.app.state.set(blockchain.app.is.ready.for.deep_link, to: false)
        }
    case .route, .binding:
        return .none
    }
}
.binding()
.routing()
.published()
