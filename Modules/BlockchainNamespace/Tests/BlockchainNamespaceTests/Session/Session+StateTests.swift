@testable import BlockchainNamespace
import Combine
import XCTest

final class SessionStateTests: XCTestCase {

    var app = App()
    var state: Session.State { app.state }

    override func setUp() {
        super.setUp()
        app = App()
    }

    func test_set_computed_value() throws {

        var iterator = [true, false].makeIterator()
        state.set(blockchain.user.is.tier.gold, to: { iterator.next()! })

        let a = try state.get(blockchain.user.is.tier.gold) as? Bool
        let b = try state.get(blockchain.user.is.tier.gold) as? Bool

        XCTAssertNotEqual(a, b)
    }

    func test_publisher_without_equatable_type_produces_duplicates() throws {

        let error = expectation(description: "did keyDoesNotExist error")
        let value = expectation(description: "did publish value")
        value.expectedFulfillmentCount = 2

        let it = state.publisher(for: blockchain.user.is.tier.gold)
            .sink { result in
                switch result {
                case .value:
                    value.fulfill()
                case .error(.keyDoesNotExist, _):
                    error.fulfill()
                case .error(let error, _):
                    XCTFail("Unexpected failure case \(error)")
                }
            }

        wait(for: [error], timeout: 1)

        state.set(blockchain.user.is.tier.gold, to: true)
        state.set(blockchain.user.is.tier.gold, to: true)

        wait(for: [value], timeout: 1)

        _ = it
    }

    func test_publisher_with_type() throws {

        let error = expectation(description: "did keyDoesNotExist error")
        let value = expectation(description: "did publish value")
        value.expectedFulfillmentCount = 2

        let it = app.publisher(for: blockchain.app.process.deep_link.url)
            .sink { result in
                switch result {
                case .value:
                    value.fulfill()
                case .error(.keyDoesNotExist, _):
                    error.fulfill()
                case .error(let error, _):
                    XCTFail("Unexpected failure case \(error)")
                }
            }

        state.set(blockchain.app.process.deep_link.url, to: URL(string: "https://www.blockchain.com")!)
        state.set(blockchain.app.process.deep_link.url, to: URL(string: "https://www.blockchain.com/app")!)

        wait(for: [value, error], timeout: 1)

        _ = it
    }

    func test_transaction_rollback() throws {

        enum Explicit: Error { case error }

        state.set(blockchain.user.is.tier.gold, to: true)

        state.transaction { state in
            state.set(blockchain.user.is.tier.gold, to: false)
            state.clear(blockchain.user.is.tier.gold)
            throw Explicit.error
        }

        try XCTAssertTrue(state.get(blockchain.user.is.tier.gold) as? Bool ?? false)
    }

    func test_preference() throws {

        state.data.preferences = Mock.UserDefaults()
        let id = "160c4c417f8490658a8396d0283fb0d6fb98c327"

        state.set(blockchain.user.id, to: id)
        state.set(blockchain.session.state.preference.value, to: true)

        do {
            let object = state.data.preferences.object(
                forKey: "blockchain.session.state"
            )
            try XCTAssertAnyEqual(state.get(blockchain.session.state.preference.value), true)
            try XCTAssertEqual(
                object[id, "blockchain.session.state.preference.value"].unwrap() as? Bool,
                true
            )
        }

        state.clear(blockchain.user.id)

        do {
            let object = state.data.preferences.object(
                forKey: "blockchain.session.state"
            )
            XCTAssertThrowsError(try state.get(blockchain.session.state.preference.value))
            try XCTAssertAnyEqual(object[id].unwrap(), [:])
        }

        state.set(blockchain.user.id, to: id)

        state.set(blockchain.app.configuration.is.biometric.enabled, to: true)

        do {
            let object = state.data.preferences.object(
                forKey: "blockchain.session.state"
            )
            try XCTAssertAnyEqual(state.get(blockchain.app.configuration.is.biometric.enabled), true)
            try XCTAssertEqual(
                object[id, "blockchain.app.configuration.is.biometric.enabled"].unwrap() as? Bool,
                true
            )
        }

        state.clear(blockchain.user.id)

        do {
            let object = state.data.preferences.object(
                forKey: "blockchain.session.state"
            )
            try XCTAssertAnyEqual(state.get(blockchain.app.configuration.is.biometric.enabled), true)
            try XCTAssertEqual(
                object[id, "blockchain.app.configuration.is.biometric.enabled"].unwrap() as? Bool,
                true
            )
        }
    }
}

extension Mock {

    class UserDefaults: Foundation.UserDefaults {

        var store: [String: Any] = [:]

        override func object(forKey defaultName: String) -> Any? {
            store[defaultName]
        }

        override func set(_ value: Any?, forKey defaultName: String) {
            store[defaultName] = value
        }
    }
}
