// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import MetadataKit
import ToolKit
import WalletCore

public struct HDWallet: Equatable {
    public let seedHex: String
    public let passphrase: String
    public let mnemonicVerified: Bool
    public let defaultAccountIndex: Int
    public let accounts: [Account]

    public init(
        seedHex: String,
        passphrase: String,
        mnemonicVerified: Bool,
        defaultAccountIndex: Int,
        accounts: [Account]
    ) {
        self.seedHex = seedHex
        self.passphrase = passphrase
        self.mnemonicVerified = mnemonicVerified
        self.defaultAccountIndex = defaultAccountIndex
        self.accounts = accounts
    }
}

// MARK: - HDWallet Creation

/// Creates a new `HDWallet` from the given mnemonic
/// - Parameters:
///   - mnemonic: A `String` representing a mnemonic phrase for this HDWallet
///   - accountName: A `String` representing the wallet's name
///   - totalAccounts: A `Int` for the total `Account`s to be created
///
/// Note: We create both legacy and segwit accounts
///
/// - Returns: Result<HDWallet, WalletCreateError>
func generateHDWallet(
    mnemonic: String,
    accountName: String,
    totalAccounts: Int = 1
) -> Result<HDWallet, WalletCreateError> {
    getHDWallet(from: mnemonic)
        .flatMap { hdWallet -> Result<(accounts: [Account], seedHex: String), WalletCreateError> in
            let seedHex = hdWallet.entropy.toHexString()
            let masterSeedHex = hdWallet.seed.toHexString()
            let accounts = provideAccounts(count: totalAccounts, masterSeedHex: masterSeedHex, label: accountName)
            return .success((accounts, seedHex))
        }
        .map { accounts, seedHex in
            HDWallet(
                seedHex: seedHex,
                passphrase: "",
                mnemonicVerified: false,
                defaultAccountIndex: 0,
                accounts: accounts
            )
        }
}

/// Provides an array of `Account`s up to the given `count` and parameters
/// - Parameters:
///   - count: An `Int` for the total accounts to be created
///   - seedHex: A `String` to be used as a seed hex
///   - label: A `String` to used as a prefix for each account
/// - Returns: An array of `Account`
private func provideAccounts(
    count: Int,
    masterSeedHex: String,
    label: String
) -> [Account] {
    (0..<count).map { index in
        generateAccount(masterSeedHex: masterSeedHex, index: index, label: label)
    }
}

/// Creates an `Account` from the given parameters
/// - Parameters:
///   - seedHex: A `String` to be used as a seed hex
///   - index: An `Int` to be used for the derivation
///   - label: A `String` to used as a prefix for each account
/// - Returns: A `Result<Account, WalletCreateError>`
private func generateAccount(
    masterSeedHex: String,
    index: Int,
    label: String
) -> Account {
    let derivations = generateDerivations(masterSeedHex: masterSeedHex, index: index)
    let label = index > 0 ? "\(label)\(index + 1)" : label
    return createAccount(label: label, derivations: derivations)
}
