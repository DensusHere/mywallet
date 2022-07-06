// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors
import Foundation

public protocol ProductsServiceAPI {

    func fetchProducts() -> AnyPublisher<[Product], NabuNetworkError>
}
