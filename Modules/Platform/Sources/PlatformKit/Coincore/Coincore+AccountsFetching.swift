// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import RxSwift
import RxToolKit
import ToolKit

extension PrimitiveSequenceType where Trait == SingleTrait, Element == [SingleAccount] {

    /// Maps each `[SingleAccount]` object filtering out accounts that match the given `BlockchainAccount` identifier.
    public func mapFilter(excluding identifier: AnyHashable) -> PrimitiveSequence<SingleTrait, Element> {
        map { accounts in
            accounts.filter { $0.identifier != identifier }
        }
    }
}

extension AccountGroup {

    public func accounts(
        supporting action: AssetAction,
        failSequence: Bool = false,
        onFailure: ((SingleAccount, Error) -> Void)? = nil
    ) -> Single<[SingleAccount]> {
        accountsPublisher(
            supporting: action,
            failSequence: failSequence,
            onFailure: onFailure
        )
        .asSingle()
    }

    public func accountsPublisher(
        supporting action: AssetAction,
        failSequence: Bool = false,
        onFailure: ((SingleAccount, Error) -> Void)? = nil
    ) -> AnyPublisher<[SingleAccount], Error> {
        .just(accounts)
            .flatMapFilter(
                action: action,
                failSequence: failSequence,
                onFailure: onFailure
            )
    }
}

extension Publisher where Output == [BlockchainAccount], Failure == Error {

    /// Filters an `[BlockchainAccount]` for only `BlockchainAccount`s that can perform the given action.
    /// - parameter failSequence: When `true` re-throws errors raised by any `BlockchainAccount.can(perform:)`.
    ///  If this is set to `false`, filters out from the emitted element any account whose `BlockchainAccount.can(perform:)` failed.
    public func flatMapFilter(
        action: AssetAction? = nil,
        failSequence: Bool = false,
        onFailure: ((BlockchainAccount, Failure) -> Void)? = nil
    ) -> AnyPublisher<[BlockchainAccount], Failure> {
        flatMap { accounts -> AnyPublisher<[BlockchainAccount], Failure> in
            guard let action = action else {
                return .just(accounts)
            }
            return accounts.map { account in
                // Check if account can perform action
                account.can(perform: action)
                    // If account can perform, return itself, else return nil
                    .map { $0 ? account : nil }
                    .tryCatch { error -> AnyPublisher<BlockchainAccount?, Failure> in
                        Logger.shared.error(
                            "[Coincore] Error checking if account can perform '\(action)' => \(error)"
                        )
                        onFailure?(account, error)
                        if failSequence {
                            throw error
                        }
                        return .just(nil)
                    }
                    .eraseToAnyPublisher()
            }
            .zip()
            // Filter nil elements (accounts that can't perform action)
            .map { accounts in
                accounts.compactMap { $0 }
            }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}

extension Publisher where Output == [SingleAccount], Failure == Error {

    public func flatMapFilter(
        address: String,
        onFailure: ((Failure) -> Void)? = nil
    ) -> AnyPublisher<SingleAccount, Failure> {
        flatMap { accounts -> AnyPublisher<SingleAccount, Failure> in
            accounts
                .compactMap { account in
                    account
                        .receiveAddress
                        .map(\.address)
                        .map { receiveAddress in
                            receiveAddress == address ? account : nil
                        }
                        .tryCatch { error -> AnyPublisher<SingleAccount?, Failure> in
                            onFailure?(error)
                            return .just(nil)
                        }
                        .eraseToAnyPublisher()
                }
                .zip()
                .map { accounts in
                    accounts.compactMap { $0 }
                }
                .tryMap { accounts in
                    guard let account = accounts.first else {
                        throw PlatformKitError.default
                    }
                    return account
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    /// Filters an `[SingleAccount]` for only `SingleAccount`s that can perform the given action.
    /// - parameter failSequence: When `true` re-throws errors raised by any `SingleAccount.can(perform:)`.
    ///  If this is set to `false`, filters out from the emitted element any account whose `SingleAccount.can(perform:)` failed.
    public func flatMapFilter(
        action: AssetAction? = nil,
        failSequence: Bool = false,
        onFailure: ((SingleAccount, Failure) -> Void)? = nil
    ) -> AnyPublisher<[SingleAccount], Failure> {
        flatMap { accounts -> AnyPublisher<[SingleAccount], Failure> in
            guard let action = action else {
                return .just(accounts)
            }
            return accounts.map { account in
                // Check if account can perform action
                account.can(perform: action)
                    // If account can perform, return itself, else return nil
                    .map { $0 ? account : nil }
                    .tryCatch { error -> AnyPublisher<SingleAccount?, Failure> in
                        Logger.shared.error(
                            "[Coincore] Error checking if account can perform '\(action)' => \(error)"
                        )
                        onFailure?(account, error)
                        if failSequence {
                            throw error
                        }
                        return .just(nil)
                    }
                    .eraseToAnyPublisher()
            }
            .zip()
            // Filter nil elements (accounts that can't perform action)
            .map { accounts in
                accounts.compactMap { $0 }
            }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}

extension Publisher where Output == AccountGroup, Failure == Error {

    public func flatMapFilter(
        action: AssetAction? = nil,
        failSequence: Bool = false,
        onFailure: ((SingleAccount, Failure) -> Void)? = nil
    ) -> AnyPublisher<[SingleAccount], Failure> {
        map(\.accounts)
            .flatMapFilter(
                action: action,
                failSequence: failSequence,
                onFailure: onFailure
            )
    }

    fileprivate func mapToCryptoAccounts(
        supporting action: AssetAction?
    ) -> AnyPublisher<[CryptoAccount], Failure> {
        flatMapFilter(action: action)
            .map { accounts in
                accounts
                    .compactMap { $0 as? CryptoAccount }
                    .sorted { lhs, rhs in
                        lhs.asset < rhs.asset
                    }
            }
            .eraseToAnyPublisher()
    }
}

extension CoincoreAPI {

    public func cryptoAccounts(
        supporting action: AssetAction? = nil,
        filter: AssetFilter = .all
    ) -> AnyPublisher<[CryptoAccount], Error> {
        allAssets
            .map { asset in
                asset.accountGroup(filter: filter)
                    .eraseError()
                    .mapToCryptoAccounts(supporting: action)
            }
            .zip()
            .map { accountsMatrix in
                // the result is an array of arrays of accounts, so flatten it to a single array of accounts
                Array(accountsMatrix.joined())
            }
            .eraseToAnyPublisher()
    }

    public func cryptoAccounts(
        for cryptoCurrency: CryptoCurrency,
        supporting action: AssetAction? = nil,
        filter: AssetFilter = .all
    ) -> AnyPublisher<[CryptoAccount], Error> {
        let asset = self[cryptoCurrency]
        return asset.accountGroup(filter: filter)
            .eraseError()
            .mapToCryptoAccounts(supporting: action)
    }

    public var uniqueCryptoAccountsByAssetThatSupportBuy: AnyPublisher<[CryptoAccount], Error> {
        cryptoAccounts(supporting: .buy)
            .map { accounts in
                var dictionary: [CryptoCurrency: CryptoAccount] = [:]
                for account in accounts {
                    dictionary[account.asset] = account
                }
                return Array(dictionary.values)
                    .sorted { lhs, rhs in
                        lhs.asset < rhs.asset
                    }
            }
            .eraseToAnyPublisher()
    }
}

public enum AssetType {
    case all
    case fiat
    case crypto
}

extension CoincoreAPI {

    public func hasFundedAccounts(for assetType: AssetType) -> AnyPublisher<Bool, Error> {
        let accountsPublisher: AnyPublisher<[SingleAccount], Error>
        switch assetType {
        case .all:
            accountsPublisher = allAccounts
                .map(\.accounts)
                .eraseError()
                .eraseToAnyPublisher()
        case .fiat:
            accountsPublisher = fiatAsset
                .accountGroup(filter: .all)
                .map(\.accounts)
                .eraseError()
                .eraseToAnyPublisher()
        case .crypto:
            accountsPublisher = cryptoAccounts()
                .map { accounts in
                    accounts.map { $0 as SingleAccount }
                }
                .eraseToAnyPublisher()
        }
        return accountsPublisher.hasAnyFundedAccounts()
    }

    public func hasPositiveDisplayableBalanceAccounts(for assetType: AssetType) -> AnyPublisher<Bool, Error> {
        let accountsPublisher: AnyPublisher<[SingleAccount], Error>
        switch assetType {
        case .all:
            accountsPublisher = allAccounts
                .map(\.accounts)
                .eraseError()
                .eraseToAnyPublisher()
        case .fiat:
            accountsPublisher = fiatAsset
                .accountGroup(filter: .all)
                .map(\.accounts)
                .eraseError()
                .eraseToAnyPublisher()
        case .crypto:
            accountsPublisher = cryptoAccounts()
                .map { accounts in
                    accounts.map { $0 as SingleAccount }
                }
                .eraseToAnyPublisher()
        }
        return accountsPublisher.hasPositiveDisplayableBalanceAccounts()
    }
}

extension Sequence where Element == SingleAccount {

    public func hasAnyFundedAccounts() -> AnyPublisher<Bool, Error> {
        map(\.isFunded)
            .zip()
            .map { results -> Bool in
                results.contains(true)
            }
            .eraseToAnyPublisher()
    }

    public func hasPositiveDisplayableBalanceAccounts() -> AnyPublisher<Bool, Error> {
        map(\.hasPositiveDisplayableBalance)
            .zip()
            .map { results -> Bool in
                results.contains(true)
            }
            .eraseToAnyPublisher()
    }
}

extension Publisher where Output: Sequence, Output.Element == SingleAccount, Failure == Error {

    public func hasAnyFundedAccounts() -> AnyPublisher<Bool, Failure> {
        flatMap { accounts -> AnyPublisher<Bool, Failure> in
            accounts.hasAnyFundedAccounts()
        }
        .eraseToAnyPublisher()
    }

    public func hasPositiveDisplayableBalanceAccounts() -> AnyPublisher<Bool, Failure> {
        flatMap { accounts -> AnyPublisher<Bool, Failure> in
            accounts.hasPositiveDisplayableBalanceAccounts()
        }
        .eraseToAnyPublisher()
    }
}
