// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors
import Foundation

final class ProductsService: ProductsServiceAPI {

    private let repository: ProductsRepositoryAPI

    init(
        repository: ProductsRepositoryAPI
    ) {
        self.repository = repository
    }

    func fetchProducts() -> AnyPublisher<[Product], NabuNetworkError> {
        repository.fetchProducts()
    }
}
