// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
@testable import FeatureCryptoDomainData
import Foundation
import NetworkError

final class MockSearchDomainClient: SearchDomainClientAPI {

    var mockSearchResultResponseFilePath: String? {
        Bundle.main.path(forResource: "search_result_response_mock", ofType: "json")
    }

    func getSearchResults(searchKey: String) -> AnyPublisher<SearchResultResponse, NetworkError> {
        let data = """
        {
          "searchedDomain": {
            "domain": {
              "id": 962841,
              "name": "testkey.blockchain",
              "ownerAddress": null,
              "resolver": null,
              "resolution": {},
              "blockchain": "MATIC",
              "registryAddress": "0x2a93c52e7b6e7054870758e15a1446e769edfb93",
              "networkId": 80001,
              "freeToClaim": true,
              "node": "0x5fde1f88ff63bc18a058e4f6d67ada2ebc0b3321290b3176c006ad961d6f7ad1"
            },
            "availability": {
              "registered": false,
              "protected": false,
              "price": 100000,
              "availableForFree": false,
              "test": false
            }
          },
          "suggestions": [
            {
              "name": "testkey98.blockchain",
              "price": 0
            },
            {
              "name": "wisetestkey60.blockchain",
              "price": 0
            },
            {
              "name": "wrytestkey153.blockchain",
              "price": 0
            },
            {
              "name": "oddtestkey116.blockchain",
              "price": 0
            },
            {
              "name": "oilytestkey271.blockchain",
              "price": 0
            },
            {
              "name": "testkeymara475.blockchain",
              "price": 0
            },
            {
              "name": "uglytestkey369.blockchain",
              "price": 0
            },
            {
              "name": "testkeypika890.blockchain",
              "price": 0
            },
            {
              "name": "testkeyorca133.blockchain",
              "price": 0
            },
            {
              "name": "hugetestkey296.blockchain",
              "price": 0
            },
            {
              "name": "testkeytiti138.blockchain",
              "price": 0
            },
            {
              "name": "dafttestkey394.blockchain",
              "price": 0
            },
            {
              "name": "tipsytestkey861.blockchain",
              "price": 0
            },
            {
              "name": "mutedtestkey742.blockchain",
              "price": 0
            },
            {
              "name": "sacredtestkey66.blockchain",
              "price": 0
            },
            {
              "name": "stouttestkey113.blockchain",
              "price": 0
            },
            {
              "name": "testkeyakita154.blockchain",
              "price": 0
            },
            {
              "name": "testkeyplott476.blockchain",
              "price": 0
            },
            {
              "name": "cleartestkey118.blockchain",
              "price": 0
            },
            {
              "name": "spicytestkey559.blockchain",
              "price": 0
            },
            {
              "name": "plumptestkey681.blockchain",
              "price": 0
            },
            {
              "name": "inerttestkey123.blockchain",
              "price": 0
            },
            {
              "name": "tritetestkey964.blockchain",
              "price": 0
            },
            {
              "name": "shrewdtestkey85.blockchain",
              "price": 0
            },
            {
              "name": "lividtestkey886.blockchain",
              "price": 0
            },
            {
              "name": "frailtestkey767.blockchain",
              "price": 0
            },
            {
              "name": "browntestkey128.blockchain",
              "price": 0
            },
            {
              "name": "testkeycolugo91.blockchain",
              "price": 0
            },
            {
              "name": "testkeyquoll372.blockchain",
              "price": 0
            },
            {
              "name": "bushytestkey774.blockchain",
              "price": 0
            }
          ]
        }
        """.data(using: .utf8)!
        // let data = try! Data(contentsOf: URL(fileURLWithPath: mockSearchResultResponseFilePath!), options: .mappedIfSafe)
        let response = try! JSONDecoder().decode(SearchResultResponse.self, from: data)
        return .just(response)
    }
}
