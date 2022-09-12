// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BitcoinChainKit

struct BitcoinWalletAccount: Equatable {

    // MARK: Properties

    let archived: Bool
    let index: Int
    let label: String?
    let publicKeys: XPubs

    // MARK: Internal Properties

    var isActive: Bool {
        !archived
    }

    // MARK: Initializers

    init(index: Int, label: String?, archived: Bool, publicKeys: XPubs) {
        self.index = index
        self.label = label
        self.archived = archived
        self.publicKeys = publicKeys
    }
}
