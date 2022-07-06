// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors

/// Fetches the supported trading pairs for swap.
protocol TradingPairsClientAPI: AnyObject {
    func tradingPairs() -> AnyPublisher<[String], NabuNetworkError>
}
