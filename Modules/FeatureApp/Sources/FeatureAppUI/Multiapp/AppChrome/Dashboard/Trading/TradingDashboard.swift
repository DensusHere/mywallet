// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import ComposableArchitecture
import ComposableArchitectureExtensions
import DIKit
import FeatureDashboardDomain
import FeatureDashboardUI
import Foundation
import SwiftUI

public struct TradingDashboard: ReducerProtocol {
    let app: AppProtocol
    let allCryptoAssetService: AllCryptoAssetsServiceAPI

    public enum Route: NavigationRoute {
        case showAllAssets

        public func destination(in store: Store<State, Action>) -> some View {
            switch self {

            case .showAllAssets:
                return AllAssetsSceneView(store: store.scope(state: \.allAssetsState, action: Action.allAssetsAction))
            }
        }
    }

    public enum Action: Equatable, NavigationAction {
        case route(RouteIntent<Route>?)
        case allAssetsAction(AllAssetsScene.Action)
        case assetsAction(DashboardAssetsSection.Action)
        case activityAction(DashboardActivitySection.Action)
    }

    public struct State: Equatable, NavigationState {
        public var title: String
        public var frequentActions: FrequentActions = .init(list: [], buttons: [])
        public var assetsState: DashboardAssetsSection.State = .init(presentedAssetsType: .custodial)
        public var allAssetsState: AllAssetsScene.State = .init(with: .custodial)
        public var activityState: DashboardActivitySection.State = .init()
        public var route: RouteIntent<Route>?

        public init(title: String) {
            self.title = title
        }
    }

    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.assetsState, action: /Action.assetsAction) {
            DashboardAssetsSection(
                allCryptoAssetService: allCryptoAssetService,
                app: app
            )
        }

        Scope(state: \.allAssetsState, action: /Action.allAssetsAction) {
            AllAssetsScene(
                allCryptoService: allCryptoAssetService,
                app: app
            )
        }

//        Scope(state: \.activityState, action: /Action.activityAction) {
//            DashboardActivitySection(
//                app: app,
//
//            )
//        }

        Reduce { state, action in
            switch action {
            case .route(let routeIntent):
                state.route = routeIntent
                return .none
            case .assetsAction(let action):
                switch action {
                case .onAllAssetsTapped:
                    state.route = .navigate(to: .showAllAssets)
                    return .none
                default:
                    return .none
                }
            case .allAssetsAction:
                return .none
            case .activityAction:
                return .none
            }
        }
    }
}
