// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

public struct PostOrderResponse: Decodable {
    var isFree: Bool
    var redirectUrl: String?
    var order: Order?
}

struct Order: Decodable {
    var orderNumber: String?
    var payment: Payment?
    var items: [Item]?
    var total: Int?
}

struct Payment: Decodable {
    var method: String?
}

struct Item: Decodable {
    var mintingTransaction: MintingTransaction?
    var domain: Domain?
}

struct MintingTransaction: Decodable {
    var statusGroup: String?
    var type: String?
    var id: Int?
    var blockchain: String?
    var operation: String?
}

struct Domain: Decodable {
    var node: String?
    var networkId: Int?
    var freeToClaim: Bool?
    var name: String?
    var id: Int?
    var blockchain: String?
    var registryAddress: String?
}
