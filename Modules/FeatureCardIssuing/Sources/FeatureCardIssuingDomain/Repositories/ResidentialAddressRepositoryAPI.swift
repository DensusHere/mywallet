// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors
import Foundation

public protocol ResidentialAddressRepositoryAPI {

    func fetchResidentialAddress() -> AnyPublisher<Card.Address, NabuNetworkError>
    func update(residentialAddress: Card.Address) -> AnyPublisher<Card.Address, NabuNetworkError>
}
