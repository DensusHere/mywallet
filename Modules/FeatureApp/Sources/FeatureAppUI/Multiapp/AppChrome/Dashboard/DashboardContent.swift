// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import Collections
import ComposableArchitecture
import DIKit

struct TradingTabsState: Equatable {
    var selectedTab: Tag.Reference = blockchain.ux.user.portfolio[].reference

    var home: TradingDashboard.State = .init(title: "Trading")
}

struct DefiTabsState: Equatable {
    var selectedTab: Tag.Reference = blockchain.ux.user.portfolio[].reference

    var home: PKWDashboard.State = .init(title: "DeFi")
}

struct DashboardContent: ReducerProtocol {
    @Dependency(\.app) var app

    struct State: Equatable {
        let appMode: AppMode
        var tabs: OrderedSet<Tab>?
        var selectedTab: Tag.Reference {
            switch appMode {
            case .pkw:
                return defiState.selectedTab
            case .trading, .universal:
                return tradingState.selectedTab
            }
        }
        // Tabs
        var tradingState: TradingTabsState = .init()
        var defiState: DefiTabsState = .init()
    }

    enum Action {
        case onAppear
        case tabs(OrderedSet<Tab>?)
        case select(Tag.Reference)
        // Tabs
        case tradingHome(TradingDashboard.Action)
        case defiHome(PKWDashboard.Action)
    }

    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.tradingState.home, action: (/Action.tradingHome)) {
            // TODO: DO NOT rely on DIKit...
            TradingDashboard(app: app, allCryptoAssetService: DIKit.resolve())
        }
        Scope(state: \.defiState.home, action: /Action.defiHome) {
            PKWDashboard(app: app, allCryptoAssetService: DIKit.resolve(), activityRepository: DIKit.resolve())
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { [state] send in
                    switch state.appMode {
                    case .trading, .universal:
                        for await event in app.stream(blockchain.app.configuration.superapp.brokerage.tabs, as: OrderedSet<Tab>.self) {
                            await send(.tabs(event.value))
                        }
                    case .pkw:
                        for await event in app.stream(blockchain.app.configuration.superapp.defi.tabs, as: OrderedSet<Tab>.self) {
                            await send(.tabs(event.value))
                        }
                    }
                }
            case .tabs(let tabs):
                state.tabs = tabs
                return .none
            case .select(let tag):
                switch state.appMode {
                case .trading, .universal:
                    state.tradingState.selectedTab = tag
                case .pkw:
                    state.defiState.selectedTab = tag
                }
                return .none
            case .tradingHome:
                return .none
            case .defiHome:
                return .none
            }
        }
    }
}
