// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine

public protocol AddressSearchRouterAPI {

    func presentSearchAddressFlow(
        prefill: Address?,
        config: AddressSearchFeatureConfig
    ) -> AnyPublisher<Address?, Never>

    func presentEditAddressFlow(
        isPresentedWithSearchView: Bool,
        config: AddressSearchFeatureConfig.AddressEditScreenConfig
    ) -> AnyPublisher<Address?, Never>
}
