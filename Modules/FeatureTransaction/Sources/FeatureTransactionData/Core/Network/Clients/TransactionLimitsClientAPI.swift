// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors
import FeatureTransactionDomain
import MoneyKit
import PlatformKit

protocol TransactionLimitsClientAPI {

    func fetchTradeLimits(
        currency: CurrencyType,
        product: TransactionLimitsProduct
    ) -> AnyPublisher<TradeLimitsResponse, NabuNetworkError>

    func fetchCrossBorderLimits(
        source: LimitsAccount,
        destination: LimitsAccount,
        limitsCurrency: CurrencyType
    ) -> AnyPublisher<CrossBorderLimitsResponse, NabuNetworkError>
}
