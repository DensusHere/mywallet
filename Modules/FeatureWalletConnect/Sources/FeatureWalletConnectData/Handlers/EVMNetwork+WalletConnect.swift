// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import EthereumKit

extension EVMNetwork {
    init?(int chainID: Int?) {
        guard let chainID = chainID else {
            self = .ethereum
            return
        }
        self.init(chainID: BigUInt(chainID))
    }
}
