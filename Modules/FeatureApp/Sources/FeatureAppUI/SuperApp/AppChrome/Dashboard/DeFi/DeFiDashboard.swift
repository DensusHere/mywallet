// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Combine
import ComposableArchitecture
import ComposableArchitectureExtensions
import DIKit
import FeatureAnnouncementsDomain
import FeatureAnnouncementsUI
import FeatureAppDomain
import FeatureDashboardDomain
import FeatureDashboardUI
import FeatureWithdrawalLocksDomain
import Foundation
import MoneyKit
import SwiftUI
import UnifiedActivityDomain

public struct DeFiDashboard: ReducerProtocol {
    @Dependency(\.mainQueue) var mainQueue

    let app: AppProtocol
    let assetBalanceInfoRepository: AssetBalanceInfoRepositoryAPI
    let activityRepository: UnifiedActivityRepositoryAPI
    let withdrawalLocksRepository: WithdrawalLocksRepositoryAPI

    public enum Action: Equatable {
        case fetchBalance
        case balanceFetched(Result<BalanceInfo, BalanceInfoError>)
        case assetsAction(DashboardAssetsSection.Action)
        case announcementAction(DashboardAnnouncementsSection.Action)
        case allAssetsAction(AllAssetsScene.Action)
        case activityAction(DashboardActivitySection.Action)
        case allActivityAction(AllActivityScene.Action)
        case announcementsAction(FeatureAnnouncements.Action)
    }

    public struct State: Equatable {
        public var balance: BalanceInfo?
        public var frequentActions: FrequentActions = .init(
            withBalance: .init(
                list: [],
                buttons: []
            ),
            zeroBalance: .init(
                list: [],
                buttons: []
            )
        )
        public var assetsState: DashboardAssetsSection.State = .init(presentedAssetsType: .nonCustodial)
        public var allAssetsState: AllAssetsScene.State = .init(with: .nonCustodial)
        public var allActivityState: AllActivityScene.State = .init(with: .nonCustodial)
        public var activityState: DashboardActivitySection.State = .init(with: .nonCustodial)
        public var announcementState: DashboardAnnouncementsSection.State = .init()
        public var announcementsState: FeatureAnnouncements.State = .init()
    }

    struct FetchBalanceId: Hashable {}

    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \State.assetsState, action: /Action.assetsAction) { () -> DashboardAssetsSection in
            DashboardAssetsSection(
                assetBalanceInfoRepository: assetBalanceInfoRepository,
                withdrawalLocksRepository: withdrawalLocksRepository,
                app: app
            )
        }

        Scope(state: \.allAssetsState, action: /Action.allAssetsAction) { () -> AllAssetsScene in
            AllAssetsScene(
                assetBalanceInfoRepository: assetBalanceInfoRepository,
                app: app
            )
        }

        Scope(state: \.allActivityState, action: /Action.allActivityAction) { () -> AllActivityScene in
            AllActivityScene(
                activityRepository: activityRepository,
                custodialActivityRepository: resolve(),
                app: app
            )
        }

        Scope(state: \.activityState, action: /Action.activityAction) { () -> DashboardActivitySection in
            DashboardActivitySection(
                app: app,
                activityRepository: activityRepository,
                custodialActivityRepository: resolve()
            )
        }

        Scope(state: \.announcementState, action: /Action.announcementAction) { () -> DashboardAnnouncementsSection in
            DashboardAnnouncementsSection(
                app: app,
                recoverPhraseProviding: resolve()
            )
        }

        Scope(state: \.announcementsState, action: /Action.announcementsAction) { () -> FeatureAnnouncements in
            FeatureAnnouncements(
                app: app,
                mainQueue: mainQueue,
                mode: .defi,
                service: resolve()
            )
        }

        Reduce { state, action in
            switch action {
            case .fetchBalance:
                return .run { send in
                    for await balanceValue in app.stream(blockchain.ux.dashboard.total.defi.balance, as: BalanceInfo.self) {
                        if let value = balanceValue.value {
                            await send(Action.balanceFetched(.success(value)))
                        }
                    }
                }
            case .balanceFetched(.success(let info)):
                state.balance = info
                return .none
            case .balanceFetched(.failure):
                return .none
            case .announcementsAction:
                return .none
            case .allAssetsAction(let action):
                switch action {
                default:
                    return .none
                }
            case .activityAction(let action):
                switch action {
                case .onAllActivityTapped:
                    return .none
                default:
                    return .none
                }
            case .assetsAction(let action):
                switch action {
                case .onAllAssetsTapped:
                    return .none
                default:
                    return .none
                }
            case .announcementAction:
                return .none
            case .allActivityAction(let action):
                switch action {
                case .onCloseTapped:
                    return .none
                default:
                    return .none
                }
            }
        }
    }
}
