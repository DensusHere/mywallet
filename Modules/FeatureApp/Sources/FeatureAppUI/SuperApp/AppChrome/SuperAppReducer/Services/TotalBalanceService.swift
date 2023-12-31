// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Blockchain
import ComposableArchitecture
import DIKit
import FeatureAppDomain
import FeatureDashboardDomain
import Foundation
import MoneyKit
import ToolKit

struct TotalBalanceInfo: Equatable {
    let total: MoneyValue
}

struct TotalBalanceService {
    var totalBalance: () -> AsyncStream<Result<TotalBalanceInfo, Error>>
}

extension TotalBalanceService: DependencyKey {
    static var liveValue: TotalBalanceService = {
        let tradingBalanceService = TradingTotalBalanceService(app: DIKit.resolve(), repository: DIKit.resolve())
        let defiBalanceService = DeFiTotalBalanceService(app: DIKit.resolve(), repository: DIKit.resolve())
        let app: AppProtocol = DIKit.resolve()
        let live = TotalBalanceService.Live(
            tradingBalanceService: tradingBalanceService,
            defiBalanceService: defiBalanceService,
            app: app
        )
        return TotalBalanceService(
            totalBalance: live.totalBalance
        )
    }()

    static let testValue = TotalBalanceService(totalBalance: { unimplemented() })
    static let previewValue = TotalBalanceService(totalBalance: { .just(.success(.init(total: .one(currency: .USD)))) })
}

extension DependencyValues {
    var totalBalanceService: TotalBalanceService {
        get { self[TotalBalanceService.self] }
        set { self[TotalBalanceService.self] = newValue }
    }
}

// MARK: - Private

extension TotalBalanceService {
    struct Live {
        let tradingBalanceService: TradingTotalBalanceService
        let defiBalanceService: DeFiTotalBalanceService
        let app: AppProtocol

        init(
            tradingBalanceService: TradingTotalBalanceService,
            defiBalanceService: DeFiTotalBalanceService,
            app: AppProtocol
        ) {
            self.tradingBalanceService = tradingBalanceService
            self.defiBalanceService = defiBalanceService
            self.app = app
        }

        func totalBalance() -> AsyncStream<Result<TotalBalanceInfo, Error>> {
            AsyncStream(
                tradingBalanceService.fetchTotalBalance()
                    .combineLatest(defiBalanceService.fetchTotalBalance())
                    .map { trading, defi -> Result<TotalBalanceInfo, Error> in

                        if let trading = trading.success {
                            app.state.set(blockchain.ux.dashboard.total.trading.balance.info, to: trading)
                        }

                        if let defi = defi.success {
                            app.state.set(blockchain.ux.dashboard.total.defi.balance, to: defi)
                        }

                        guard let trading = trading.success, let defi = defi.success else {
                            return .failure(BalanceInfoError.unableToRetrieve)
                        }
                        do {
                            let total = try trading.balance + defi.balance
                            app.state.set(blockchain.ux.dashboard.total.balance, to: total)
                            return .success(TotalBalanceInfo(total: total))
                        } catch {
                            return .failure(error)
                        }
                    }
                    .values
            )
        }
    }
}
