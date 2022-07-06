// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors
import ToolKit

public enum ProductsServiceError: Error, Equatable {
    case network(NabuNetworkError)
}

public protocol ProductsServiceAPI {

    func fetchProducts() -> AnyPublisher<[ProductValue], ProductsServiceError>
    func streamProducts() -> AnyPublisher<Result<[ProductValue], ProductsServiceError>, Never>
}

public final class ProductsService: ProductsServiceAPI {

    private let repository: ProductsRepositoryAPI
    private let featureFlagsService: FeatureFlagsServiceAPI

    public init(
        repository: ProductsRepositoryAPI,
        featureFlagsService: FeatureFlagsServiceAPI
    ) {
        self.repository = repository
        self.featureFlagsService = featureFlagsService
    }

    public func fetchProducts() -> AnyPublisher<[ProductValue], ProductsServiceError> {
        featureFlagsService.isEnabled(.productsChecksEnabled)
            .flatMap { [repository] isEnabled -> AnyPublisher<[ProductValue], ProductsServiceError> in
                guard isEnabled else {
                    return .just([])
                }
                return repository.fetchProducts()
                    .mapError(ProductsServiceError.network)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    public func streamProducts() -> AnyPublisher<Result<[ProductValue], ProductsServiceError>, Never> {
        featureFlagsService.isEnabled(.productsChecksEnabled)
            .flatMap { [repository] isEnabled -> AnyPublisher<Result<[ProductValue], ProductsServiceError>, Never> in
                guard isEnabled else {
                    return .just(.success([]))
                }
                return repository.streamProducts()
                    .map { result in
                        result.mapError(ProductsServiceError.network)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
