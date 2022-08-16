// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Errors

public struct CardSuccessRate: Decodable {
    public let block: Bool
    public let ux: Nabu.Error.UX?

    public struct Response: Equatable {
        public let bin: String
        public let block: Bool
        public let ux: Nabu.Error.UX?

        public init(
            _ successRate: CardSuccessRate,
            bin: String
        ) {
            self.bin = bin
            self.block = successRate.block
            self.ux = successRate.ux
        }
    }
}
