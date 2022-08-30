// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Foundation

public struct AssetFilter: OptionSet, Hashable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let custodial = AssetFilter(rawValue: 1 << 0)
    public static let nonCustodial = AssetFilter(rawValue: 1 << 1)
    public static let interest = AssetFilter(rawValue: 1 << 2)
    public static let exchange = AssetFilter(rawValue: 1 << 3)

    public static let all: AssetFilter = [.custodial, .nonCustodial, .interest, .exchange]
    public static let `default`: AssetFilter = [.all]
}

extension AppMode {
    public var filter: AssetFilter {
        switch self {
        case .legacy:
            return .all
        case .defi:
            return .nonCustodial
        case .trading:
            return [.custodial, .interest]
        }
    }
}
