// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

extension Mock {

    public struct RemoteConfiguration: RemoteConfiguration_p {

        public let data: [RemoteConfigurationSource: [String: RemoteConfigurationValue]]

        public init(_ data: [RemoteConfigurationSource: [String: RemoteConfigurationValue]] = [:]) {
            self.data = data
        }

        private var __data: [String: RemoteConfigurationValue] {
            data.values.reduce(into: [:]) { sum, next in
                sum.merge(next, uniquingKeysWith: { $1 })
            }
        }

        public func fetch(
            withExpirationDuration expirationDuration: TimeInterval
        ) async throws -> RemoteConfigurationFetchStatus {
            .success
        }

        public func activate() async throws -> Bool {
            true
        }

        public func allKeys(from source: RemoteConfigurationSource) -> [String] {
            Array(data[source, default: [:]].keys)
        }

        public subscript(key: String) -> RemoteConfigurationValue {
            __data[key] ?? .init(dataValue: Data())
        }
    }

    public struct RemoteConfigurationValue: RemoteConfigurationValue_p {
        public var dataValue: Data
    }

    public enum RemoteConfigurationSource: RemoteConfigurationSource_p {
        case remote
        case `default`
        case `static`
    }

    public enum RemoteConfigurationFetchStatus: RemoteConfigurationFetchStatus_p {
        case noFetchYet
        case success
        case failure
        case throttled
    }
}

// swiftlint:disable force_try

extension Mock.RemoteConfigurationValue: ExpressibleByBooleanLiteral {

    public init(booleanLiteral value: Bool) {
        dataValue = try! JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed)
    }
}

extension Mock.RemoteConfigurationValue: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        dataValue = try! JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed)
    }
}

extension Mock.RemoteConfigurationValue: ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: Any...) {
        dataValue = try! JSONSerialization.data(withJSONObject: elements)
    }
}

extension Mock.RemoteConfigurationValue: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: Int) {
        dataValue = try! JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed)
    }
}

extension Mock.RemoteConfigurationValue: ExpressibleByDictionaryLiteral {

    public init(dictionaryLiteral elements: (String, Any)...) {
        dataValue = try! JSONSerialization.data(withJSONObject: Dictionary(uniqueKeysWithValues: elements))
    }
}

extension Mock.RemoteConfigurationValue: ExpressibleByFloatLiteral {

    public init(floatLiteral value: Double) {
        dataValue = try! JSONSerialization.data(withJSONObject: value, options: .fragmentsAllowed)
    }
}
