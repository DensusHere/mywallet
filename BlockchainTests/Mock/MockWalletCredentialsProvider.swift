// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import Blockchain
import WalletPayloadKit

class MockWalletCredentialsProvider: WalletCredentialsProviding {
    static var valid: WalletCredentialsProviding {
        MockWalletCredentialsProvider(
            legacyPassword: "blockchain"
        )
    }

    let legacyPassword: String?

    init(legacyPassword: String?) {
        self.legacyPassword = legacyPassword
    }
}
