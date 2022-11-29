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
                ),
                userInfoProvider: DIKit.resolve(),
                baseCardHelperUrl: BlockchainAPI.shared.walletHelper
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

        single(tag: CardIssuingTag.residentialAddress) {
            ResidentialAddressRepository(
                client: ResidentialAddressClient(
                    networkAdapter: DIKit.resolve(tag: DIKitContext.retail),
                    requestBuilder: DIKit.resolve(tag: DIKitContext.cardIssuing)
                )
            ) as AddressRepositoryAPI
        }

        single(tag: CardIssuingTag.shippingAddress) {
            ShippingAddressRepository() as AddressRepositoryAPI
        }

        single {
            TransactionRepository(
                client: TransactionClient(
                    networkAdapter: DIKit.resolve(tag: DIKitContext.retail),
                    requestBuilder: DIKit.resolve(tag: DIKitContext.cardIssuing)
                )
            ) as TransactionRepositoryAPI
        }

        single {
            LegalRepository(
                client: LegalClient(
                    networkAdapter: DIKit.resolve(tag: DIKitContext.retail),
                    requestBuilder: DIKit.resolve(tag: DIKitContext.cardIssuing)
                )
            ) as LegalRepositoryAPI
        }
    }
}
