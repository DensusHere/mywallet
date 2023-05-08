// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MetadataKit
import WalletConnectSign
import Web3Wallet

extension WalletConnectSessionV2 {
    /// Returns a `Session` from `WalletConnect`
    ///
    /// This searches the `getSessions()` method on `Web3Wallet`
    /// 
    public func session() -> WalletConnectSign.Session? {
        Web3Wallet.instance
            .getSessions()
            .first { session -> Bool in
                self.topic == session.topic && self.pairingTopic == session.pairingTopic
            }
    }
}
