// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit

struct InterestActivityResponse: Decodable {
    let items: [InterestActivityItemEventResponse]
}

struct InterestActivityItemEventResponse: Decodable {

    enum State: String, Decodable {
        case failed = "FAILED"
        case rejected = "REJECTED"
        case processing = "PROCESSING"
        case created = "CREATED"
        case complete = "COMPLETE"
        case pending = "PENDING"
        case manualReview = "MANUAL_REVIEW"
        case cleared = "CLEARED"
        case refunded = "REFUNDED"
        case fraudReview = "FRAUD_REVIEW"
        case unknown = "UNKNOWN"
    }

    struct InterestAmount: Decodable {
        let symbol: String
        let value: String
    }

    let amount: InterestAmount
    let amountMinor: String
    let extraAttributes: InterestAttributes?
    let id: String
    let insertedAt: String
    let state: State
    let type: String
}
