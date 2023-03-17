// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import ComposableArchitecture
import FeatureDashboardDomain
import Foundation

public enum TopMoversPresenter {
    case dashboard, prices, accountPicker

    var action: L & I_blockchain_ui_type_action & I_blockchain_db_collection {
        switch self {
        case .dashboard:
            return blockchain.ux.dashboard.top.movers.select
        case .prices:
            return blockchain.ux.prices.top.movers.select
        case .accountPicker:
            return blockchain.ux.transaction.top.movers.select
        }
    }
}

public struct DashboardTopMoversSection: ReducerProtocol {
    public let app: AppProtocol
    public let topMoversService: TopMoversServiceAPI

    public init(
        app: AppProtocol,
        topMoversService: TopMoversServiceAPI
    ) {
        self.app = app
        self.topMoversService = topMoversService
    }

    public enum Action: Equatable {
        case onAppear
        case onFilteredDataFetched([TopMoverInfo])
        case onPricesDataFetched([TopMoverInfo])
        case onFastRisingCalculated(Bool)
    }

    public struct State: Equatable {
        var presenter: TopMoversPresenter
        var isLoading: Bool
        var topMovers: [TopMoverInfo] = []
        var fastRising: Bool?

        public init(
            presenter: TopMoversPresenter,
            isLoading: Bool = false,
            topMovers: [TopMoverInfo] = []
        ) {
            self.isLoading = isLoading
            self.topMovers = topMovers
            self.presenter = presenter
        }
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { [topMovers = state.topMovers] send in
                    guard topMovers.isEmpty else {
                        return
                    }

                    let topMovers = await (try? topMoversService.getTopMovers()) ?? []
                    await send(.onPricesDataFetched(topMovers))
                }

            case .onPricesDataFetched(let topMoversData):
                return .run { run in
                    let totalNumberOfMovers = await (try? app.get(blockchain.app.configuration.dashboard.top.movers.limit, as: Int.self)) ?? 4
                    let fastRisingMinDelta = await (try? app.get(blockchain.app.configuration.prices.rising.fast.percent, as: Double.self)) ?? 4

                    let filteredData = topMoversData
                        .sorted(by: { price1, price2 in
                        guard let delta1 = price1.delta?.doubleValue,
                               let delta2 = price2.delta?.doubleValue
                        else {
                            return false
                        }
                        return abs(delta1) >= abs(delta2)
                    })
                    .prefix(totalNumberOfMovers)
                    .array

                    let hasFastRisingItem = filteredData.filter { Decimal(fastRisingMinDelta / 100).isLessThanOrEqualTo($0.delta ?? 0) }.isNotEmpty
                    await run.send(.onFastRisingCalculated(hasFastRisingItem))
                    await run.send(.onFilteredDataFetched(filteredData))
                }

            case .onFastRisingCalculated(let isFastRising):
                state.fastRising = isFastRising
                return .none

            case .onFilteredDataFetched(let topMoversData):
                state.topMovers = topMoversData

            return .none
            }
        }
    }
}
