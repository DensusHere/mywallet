// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import Localization
import MetadataKit

/// An entry model that contains information on constructing BitcoinCash wallet account
public struct BitcoinCashEntry: Equatable {
    public struct AccountEntry: Equatable {
        public let index: Int
        public let publicKey: String
        public let label: String?
        public let derivationType: DerivationType
        public let archived: Bool
    }

    public let payload: BitcoinCashEntryPayload
    public let accounts: [AccountEntry]

    public var defaultAccount: AccountEntry {
        precondition(payload.defaultAccountIndex < accounts.count)
        return accounts[payload.defaultAccountIndex]
    }

    init(payload: BitcoinCashEntryPayload, wallet: NativeWallet) {
        self.payload = payload
        let accountsData = payload.accounts
        let hdWalletAccounts = wallet.defaultHDWallet?.accounts ?? []
        accounts = hdWalletAccounts
            .enumerated()
            .map { index, btcAccount -> AccountEntry in
                let accountData = index < accountsData.count ? accountsData[index] : nil
                let extendedPublicKey = btcAccount.defaultDerivationAccount?.xpub ?? ""
                let publicKey = btcAccount.derivation(for: .legacy)?.xpub
                return AccountEntry(
                    index: btcAccount.index,
                    publicKey: publicKey ?? extendedPublicKey,
                    label: accountData?.label,
                    derivationType: btcAccount.defaultDerivation,
                    archived: accountData?.archived ?? false
                )
            }
    }

    func toMetadataEntry() -> BitcoinCashEntryPayload {
        BitcoinCashEntryPayload(
            accounts: accounts.map { $0.toMetadataEntry() },
            defaultAccountIndex: payload.defaultAccountIndex,
            hasSeen: payload.hasSeen,
            addresses: payload.addresses
        )
    }
}

extension BitcoinCashEntry.AccountEntry {
    func toMetadataEntry() -> BitcoinCashEntryPayload.Account {
        BitcoinCashEntryPayload.Account(
            archived: archived,
            label: label ?? LocalizationConstants.Account.myWallet
        )
    }
}
