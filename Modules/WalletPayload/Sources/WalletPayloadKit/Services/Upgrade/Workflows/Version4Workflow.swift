// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation

/// Upgrades the wallet to version 4
///
/// Going from version 3 to 4 we need the following steps
///  - Make the current xpriv/xpub as legacy
///  - Add a segwit (bech32) xpriv/xpub
///
final class Version4Workflow: WalletUpgradeWorkflow {

    static var supportedVersion: WalletPayloadVersion {
        .v4
    }

    func shouldPerformUpgrade(wrapper: Wrapper) -> Bool {
        !wrapper.isLatestVersion
    }

    func upgrade(wrapper: Wrapper) -> AnyPublisher<Wrapper, WalletUpgradeError> {
        getSeedHex(from: wrapper.wallet)
            .publisher
            .mapError { _ in WalletUpgradeError.unableToRetrieveSeedHex }
            .flatMap { seedHex -> AnyPublisher<HDWallet, WalletUpgradeError> in
                guard let hdWallet = wrapper.wallet.defaultHDWallet else {
                    return .failure(.upgradeFailed)
                }
                // run through the accounts of default HD Wallet
                let upgradedAccounts = hdWallet.accounts.map { account -> Account in
                    // Create the new `Bech32` (aka segwit) derivation
                    let segwitDerivation = generateDerivation(
                        type: .segwit,
                        index: account.index,
                        masterSeedHex: seedHex
                    )
                    var derivations = account.derivations
                    derivations.append(segwitDerivation)
                    return Account(
                        index: account.index,
                        label: account.label,
                        archived: account.archived,
                        defaultDerivation: .segwit,
                        derivations: derivations
                    )
                }
                let upgradedHDWallet = HDWallet(
                    seedHex: hdWallet.seedHex,
                    passphrase: hdWallet.passphrase,
                    mnemonicVerified: hdWallet.mnemonicVerified,
                    defaultAccountIndex: hdWallet.defaultAccountIndex,
                    accounts: upgradedAccounts
                )
                return .just(upgradedHDWallet)
            }
            .map { hdWallet in
                let wallet = NativeWallet(
                    guid: wrapper.wallet.guid,
                    sharedKey: wrapper.wallet.sharedKey,
                    doubleEncrypted: wrapper.wallet.doubleEncrypted,
                    doublePasswordHash: wrapper.wallet.doublePasswordHash,
                    metadataHDNode: wrapper.wallet.metadataHDNode,
                    options: wrapper.wallet.options,
                    hdWallets: [hdWallet],
                    addresses: wrapper.wallet.addresses
                )
                return Wrapper(
                    pbkdf2Iterations: Int(wrapper.pbkdf2Iterations),
                    version: Version4Workflow.supportedVersion.rawValue,
                    payloadChecksum: wrapper.payloadChecksum,
                    language: wrapper.language,
                    syncPubKeys: wrapper.syncPubKeys,
                    wallet: wallet
                )
            }
            .eraseToAnyPublisher()
    }
}
