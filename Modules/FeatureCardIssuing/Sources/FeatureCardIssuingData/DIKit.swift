// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureCardIssuingDomain
import NetworkKit

extension DependencyContainer {

    // MARK: - FeatureCardIssuingData Module

    public static var featureCardIssuingData = module {

        single {
            CardRepository(
                client: CardClient(
                    networkAdapter: DIKit.resolve(tag: DIKitContext.retail),
                    requestBuilder: DIKit.resolve(tag: DIKitContext.cardIssuing)
                )
            ) as CardRepositoryAPI
        }

        single {
            ProductsRepository(
                client: ProductsClient(
                    networkAdapter: DIKit.resolve(tag: DIKitContext.retail),
                    requestBuilder: DIKit.resolve(tag: DIKitContext.cardIssuing)
                )
            ) as ProductsRepositoryAPI
        }

        single {
            RewardsRepository(
                client: RewardsClient(
                    networkAdapter: DIKit.resolve(tag: DIKitContext.retail),
                    requestBuilder: DIKit.resolve(tag: DIKitContext.cardIssuing)
                )
            ) as RewardsRepositoryAPI
        }
    }
}
