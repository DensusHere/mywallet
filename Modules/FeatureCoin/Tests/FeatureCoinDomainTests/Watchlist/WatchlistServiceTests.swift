// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Combine
@testable import FeatureCoinDomain
import MoneyKit
import NetworkError
import TestKit
import XCTest

final class WatchlistServiceTests: XCTestCase {

    var app: AppProtocol!
    var watchlistRepository: WatchlistRepositoryMock!
    var sut: WatchlistService!
    var isOn: Bool?

    let code = CryptoCurrency.bitcoin.code

    override func setUp() {
        super.setUp()
        app = App.test
        isOn = nil
        watchlistRepository = WatchlistRepositoryMock()
        app.publisher(
            for: blockchain.ux.asset[code].watchlist.is.on,
            as: Bool.self
        )
        .compactMap(\.value)
        .assign(to: \.isOn, on: self)
        .store(withLifetimeOf: self)
    }

    func test_isPublishing_isOnNotOnWatchlist() throws {
        watchlistRepository.stubbedResults.getWatchlist = .just([])

        sut = WatchlistService(
            base: .bitcoin,
            watchlistRepository: watchlistRepository,
            app: app
        )

        XCTAssertFalse(isOn!)
    }

    func test_isPublishing_isOnWatchlist() throws {
        watchlistRepository.stubbedResults.getWatchlist = .just([code])

        sut = WatchlistService(
            base: .bitcoin,
            watchlistRepository: watchlistRepository,
            app: app
        )

        XCTAssertTrue(isOn!)
    }

    func test_isPublishing_isOnWatchlist_afterRemove() throws {
        watchlistRepository.stubbedResults.getWatchlist = .just([code])
        watchlistRepository.stubbedResults.removeFromWatchlist = .just(())

        sut = WatchlistService(
            base: .bitcoin,
            watchlistRepository: watchlistRepository,
            app: app
        )

        app.post(event: blockchain.ux.asset[code].watchlist.remove)

        XCTAssertFalse(isOn!)
    }

    func test_isPublishing_isOnWatchlist_afterAdd() throws {
        watchlistRepository.stubbedResults.getWatchlist = .just([])
        watchlistRepository.stubbedResults.addToWatchlist = .just(())

        sut = WatchlistService(
            base: .bitcoin,
            watchlistRepository: watchlistRepository,
            app: app
        )

        app.post(event: blockchain.ux.asset[code].watchlist.add)

        XCTAssertTrue(isOn!)
    }
}
