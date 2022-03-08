// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import FeatureCryptoDomainData
@testable import FeatureCryptoDomainDomain
@testable import FeatureCryptoDomainMock
import NetworkKit
import TestKit
import XCTest

// swiftlint:disable all

class SearchDomainRepositoryTests: XCTestCase {

    var client: SearchDomainClientAPI!
    var network: ReplayNetworkCommunicator!
    var repository: SearchDomainRepositoryAPI!

    override func setUpWithError() throws {
        try super.setUpWithError()
        (client, network) = SearchDomainClient.test()
        repository = SearchDomainRepository(apiClient: client)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        client = nil
        repository = nil
    }

    func test_get_search_results() {
        _ = try! repository.searchResults(searchKey: "Searchkey").wait()
        _ = try! network.requests[
            .get, "https://api.dev.blockchain.info/explorer-gateway/resolution/ud/search/Searchkey"
        ].unwrap()
    }
}
