@testable import FeatureProductsDomain
import NabuNetworkError
import TestKit
import ToolKit
import ToolKitMock
import XCTest

final class ProductsServiceTests: XCTestCase {

    private var service: ProductsService!
    private var mockRepository: ProductsRepositoryMock!
    private var mockFeatureFlagService: MockFeatureFlagsService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockRepository = ProductsRepositoryMock()
        mockFeatureFlagService = MockFeatureFlagsService()
        service = ProductsService(
            repository: mockRepository,
            featureFlagsService: mockFeatureFlagService
        )
    }

    override func tearDownWithError() throws {
        service = nil
        mockRepository = nil
        try super.tearDownWithError()
    }

    // MARK: Fetch

    func test_fetch_returns_emptyArray_if_featureFlag_isDisabled() throws {
        XCTAssertPublisherCompletion(mockFeatureFlagService.disable(.remote(.productsChecksEnabled)))
        XCTAssertPublisherValues(service.fetchProducts(), [ProductValue]())
    }

    func test_fetch_returns_repositoryError() throws {
        XCTAssertPublisherCompletion(mockFeatureFlagService.enable(.remote(.productsChecksEnabled)))
        let error = NabuNetworkError.communicatorError(.serverError(.badResponse))
        try stubRepository(with: error)
        let publisher = service.fetchProducts()
        XCTAssertPublisherError(publisher, .network(error))
    }

    func test_fetch_returns_repositoryValues() throws {
        XCTAssertPublisherCompletion(mockFeatureFlagService.enable(.remote(.productsChecksEnabled)))
        let expectedProducts = try stubRepositoryWithDefaultProducts()
        XCTAssertPublisherValues(service.fetchProducts(), expectedProducts)
    }

    func test_stream_returns_repositoryError() throws {
        XCTAssertPublisherCompletion(mockFeatureFlagService.enable(.remote(.productsChecksEnabled)))
        let error = NabuNetworkError.communicatorError(.serverError(.badResponse))
        try stubRepository(with: error)
        XCTAssertPublisherError(service.fetchProducts(), .network(error))
    }

    // MARK: Stream

    func test_stream_returns_emptyArray_if_featureFlag_isDisabled() throws {
        XCTAssertPublisherCompletion(mockFeatureFlagService.disable(.remote(.productsChecksEnabled)))
        XCTAssertPublisherValues(service.streamProducts(), .success([]))
    }

    func test_stream_publishes_products() throws {
        XCTAssertPublisherCompletion(mockFeatureFlagService.enable(.remote(.productsChecksEnabled)))
        let expectedProducts = try stubRepositoryWithDefaultProducts()
        XCTAssertPublisherValues(service.streamProducts(), .success(expectedProducts))
    }

    // MARK: - Private

    private func stubRepository(with error: NabuNetworkError) throws {
        mockRepository.stubbedResponses.fetchProducts = .failure(error)
        mockRepository.stubbedResponses.streamProducts = .just(.failure(error))
    }

    private func stubRepository(with products: [ProductValue]) throws {
        mockRepository.stubbedResponses.fetchProducts = .just(products)
        mockRepository.stubbedResponses.streamProducts = .just(.success(products))
    }

    private func stubRepositoryWithDefaultProducts() throws -> [ProductValue] {
        let expectedProducts = [
            ProductValue.trading(
                TradingProduct(
                    id: .swap,
                    enabled: true,
                    maxOrdersCap: 1,
                    maxOrdersLeft: 0,
                    canPlaceOrder: false,
                    suggestedUpgrade: ProductSuggestedUpgrade(requiredTier: 2)
                )
            ),
            ProductValue.trading(
                TradingProduct(
                    id: .buy,
                    enabled: true,
                    maxOrdersCap: nil,
                    maxOrdersLeft: nil,
                    canPlaceOrder: true,
                    suggestedUpgrade: nil
                )
            ),
            ProductValue.custodialWallet(
                CustodialWalletProduct(
                    id: .custodialWallet,
                    enabled: true,
                    canDepositFiat: false,
                    canDepositCrypto: true,
                    canWithdrawCrypto: true,
                    canWithdrawFiat: true,
                    suggestedUpgrade: nil
                )
            )
        ]
        try stubRepository(with: expectedProducts)
        return expectedProducts
    }
}
