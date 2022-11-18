// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

public struct WithdrawalLocks: Hashable {
    public init(items: [WithdrawalLocks.Item], amount: String) {
        self.items = items
        self.amount = amount
    }

    public struct Item: Hashable, Identifiable {
        public init(
            date: String,
            amount: String,
            amountCurrency: String,
            boughtAmount: String?,
            boughtCryptoCurrency: String?
        ) {
            self.date = date
            self.amount = amount
            self.amountCurrency = amountCurrency
            self.boughtAmount = boughtAmount
            self.boughtCryptoCurrency = boughtCryptoCurrency
        }

        public var id = UUID()
        public let date: String
        public let amount: String
        public let amountCurrency: String
        public let boughtAmount: String?
        public let boughtCryptoCurrency: String?
    }

    public let items: [Item]
    public let amount: String
}
