// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import BlockchainNamespace
import Combine
import ComposableArchitecture
import ComposableArchitectureExtensions
import DIKit
import FeatureAppDomain
import FeatureDashboardDomain
import FeatureDashboardUI
import Foundation
import MoneyKit
import SwiftUI
import UnifiedActivityDomain

public struct TradingDashboard: ReducerProtocol {
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.tradingGetStartedCryptoBuyAmmountsService) var tradingGetStartedCryptoBuyAmmountsService

    let app: AppProtocol
    let assetBalanceInfoRepository: AssetBalanceInfoRepositoryAPI
    let activityRepository: UnifiedActivityRepositoryAPI
    let custodialActivityRepository: CustodialActivityRepositoryAPI

    public enum Action: BindableAction {
        case prepare
        case fetchGetStartedCryptoBuyAmmounts
        case onFetchGetStartedCryptoBuyAmmounts(TaskResult<[TradingGetStartedAmmountValue]>)
        case context(Tag.Context)
        case allAssetsAction(AllAssetsScene.Action)
        case assetsAction(DashboardAssetsSection.Action)
        case activityAction(DashboardActivitySection.Action)
        case allActivityAction(AllActivityScene.Action)
        case binding(BindingAction<TradingDashboard.State>)
        case balanceFetched(Result<BalanceInfo, BalanceInfoError>)
    }

    public struct State: Equatable {
        var context: Tag.Context?
        public var tradingBalance: BalanceInfo?
        public var getStartedBuyCryptoAmmounts: [TradingGetStartedAmmountValue] = []
        public var frequentActions: FrequentActions = .init(
            list: [],
            buttons: []
        )
        public var assetsState: DashboardAssetsSection.State = .init(presentedAssetsType: .custodial)
        public var allAssetsState: AllAssetsScene.State = .init(with: .custodial)
        public var allActivityState: AllActivityScene.State = .init(with: .custodial)
        public var activityState: DashboardActivitySection.State = .init(with: .custodial)
    }

    struct FetchBalanceId: Hashable {}

    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Scope(state: \.assetsState, action: /Action.assetsAction) {
            DashboardAssetsSection(
                assetBalanceInfoRepository: assetBalanceInfoRepository,
                app: app
            )
        }

        Scope(state: \.allAssetsState, action: /Action.allAssetsAction) {
            AllAssetsScene(
                assetBalanceInfoRepository: assetBalanceInfoRepository,
                app: app
            )
        }

        Scope(state: \.activityState, action: /Action.activityAction) {
            DashboardActivitySection(
                app: app,
                activityRepository: activityRepository,
                custodialActivityRepository: custodialActivityRepository
            )
        }

        Scope(state: \.allActivityState, action: /Action.allActivityAction) {
            AllActivityScene(
                activityRepository: activityRepository,
                custodialActivityRepository: custodialActivityRepository,
                app: app
            )
        }

        Reduce { state, action in
            switch action {
            case .context(let context):
                state.context = context
                return .none
            case .prepare:
                return .run { send in
                    let stream = app.stream(blockchain.ux.dashboard.total.trading.balance.info, as: BalanceInfo.self)
                    for await balanceValue in stream {
                        do {
                            let value = try balanceValue.get()
                            await send(Action.balanceFetched(.success(value)))
                        } catch {
                            error.localizedDescription.peek()
                            await send(Action.balanceFetched(.failure(.unableToRetrieve)))
                        }
                    }
                }

            case .balanceFetched(.success(let info)):
                state.tradingBalance = info
                if let balance = state.tradingBalance?.balance, balance.isZero {
                    return Effect.init(value: .fetchGetStartedCryptoBuyAmmounts)
                } else {
                    return .none
                }

            case .fetchGetStartedCryptoBuyAmmounts:
                return .task(priority: .userInitiated) {
                    await Action.onFetchGetStartedCryptoBuyAmmounts(
                        TaskResult { try await tradingGetStartedCryptoBuyAmmountsService.cryptoBuyAmmounts() }
                    )
                }

            case .onFetchGetStartedCryptoBuyAmmounts(.success(let ammounts)):
                state.getStartedBuyCryptoAmmounts = ammounts
                return .none

            case .onFetchGetStartedCryptoBuyAmmounts(.failure):
                return .none

            case .balanceFetched(.failure):
                // TODO: handle error?
                // what do we do in an error, hide balance? display something?
                return .none
            case .assetsAction:
                 return .none
            case .allAssetsAction:
                return .none
            case .allActivityAction(let action):
                switch action {
                case .onCloseTapped:
                    return .none
                default:
                    return .none
                }
            case .binding:
                return .none
            case .activityAction(let action):
                switch action {
                case .onAllActivityTapped:
                    return .fireAndForget {[context = state.context] in
                    if let context = context {
                        app.post(event: blockchain.ux.all.activity, context: context + [
                            blockchain.ux.all.activity.model: PresentedAssetType.custodial
                        ])
                      }
                    }
                default:
                    return .none
                }
            }
        }
    }
}
