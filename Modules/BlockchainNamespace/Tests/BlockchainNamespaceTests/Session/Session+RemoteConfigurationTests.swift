@testable import BlockchainNamespace
import Combine
import FirebaseProtocol
import XCTest

@available(iOS 15.0, macOS 12.0, *) // Replace with `async()` API when merged
final class SessionRemoteConfigurationTests: XCTestCase {

    let app = App(
        remote: Mock.RemoteConfiguration(
            [
                .remote: [
                    "ios_ff_apple_pay_is_enabled": true,
                    "blockchain_app_configuration_announcements": ["1", "2", "3"]
                ]
            ]
        )
    )

    func test_fetch() async throws {

        let announcements = try await app.publisher(for: blockchain.app.configuration.announcements, as: [String].self)
            .wait()

        XCTAssertEqual(announcements, ["1", "2", "3"])
    }

    func test_fetch_fallback() async throws {

        let isEnabled = try await app.publisher(for: blockchain.app.configuration.apple.pay.is.enabled, as: Bool.self)
            .wait()

        XCTAssertTrue(isEnabled)
    }

    func test_fetch_type_mismatch() async throws {

        let announcements = try await app.publisher(for: blockchain.app.configuration.announcements, as: Bool.self)
            .values.first
            .unwrap()

        XCTAssertThrowsError(try announcements.get())
    }

    func test_fetch_missing_value() async throws {

        let announcements = try await app.publisher(for: blockchain.user.email.address, as: String.self)
            .values.first
            .unwrap()

        XCTAssertThrowsError(try announcements.get())
    }

    func test_fetch_then_override() async throws {

        var announcements = try await app.publisher(for: blockchain.app.configuration.announcements, as: [String].self)
            .wait()

        XCTAssertEqual(announcements, ["1", "2", "3"])

        app.remoteConfiguration.override(blockchain.app.configuration.announcements[].ref(), with: ["4", "5", "6"])

        announcements = try await app.publisher(for: blockchain.app.configuration.announcements, as: [String].self)
            .wait()

        XCTAssertEqual(announcements, ["4", "5", "6"])
    }

    func test_all_keys() async throws {

        _ = try await app.publisher(for: blockchain.app.configuration.apple.pay.is.enabled)
            .values
            .first

        XCTAssertEqual(
            app.remoteConfiguration.allKeys.set,
            ["ios_ff_apple_pay_is_enabled", "blockchain_app_configuration_announcements"].set
        )
    }

    func test_with_default() async throws {

        let app = App(
            remoteConfiguration: .init(
                remote: Mock.RemoteConfiguration(),
                default: [
                    blockchain.app.configuration.apple.pay.is.enabled[].ref(): true
                ]
            )
        )

        var isEnabled = try await app.publisher(for: blockchain.app.configuration.apple.pay.is.enabled, as: Bool.self)
            .wait()

        XCTAssertTrue(isEnabled)

        XCTAssertEqual(
            app.remoteConfiguration.allKeys.set,
            ["blockchain.app.configuration.apple.pay.is.enabled"].set
        )

        app.remoteConfiguration.override(blockchain.app.configuration.apple.pay.is.enabled[].ref(), with: false)

        isEnabled = try await app.publisher(for: blockchain.app.configuration.apple.pay.is.enabled, as: Bool.self)
            .wait()

        XCTAssertEqual(
            app.remoteConfiguration.allKeys.set,
            [
                "blockchain.app.configuration.apple.pay.is.enabled",
                "!blockchain.app.configuration.apple.pay.is.enabled"
            ].set
        )

        XCTAssertFalse(isEnabled)

        app.remoteConfiguration.clear(blockchain.app.configuration.apple.pay.is.enabled[].ref())

        isEnabled = try await app.publisher(for: blockchain.app.configuration.apple.pay.is.enabled, as: Bool.self)
            .wait()

        XCTAssertTrue(isEnabled)
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension Publisher where Output == FetchResult {

    func wait() async throws -> Any {
        try await values.first
            .unwrap()
            .get()
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension Publisher where Output: FetchResult.Decoded {

    func wait() async throws -> Output.Value {
        try await values.first
            .unwrap()
            .get()
    }
}
