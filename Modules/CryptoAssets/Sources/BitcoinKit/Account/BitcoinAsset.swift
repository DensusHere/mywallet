// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BitcoinChainKit
import Combine
import DIKit
import FeatureCryptoDomainDomain
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

private struct AccountsPayload {
    let defaultAccount: BitcoinWalletAccount
    let accounts: [BitcoinWalletAccount]
}

final class BitcoinAsset: CryptoAsset {

    let asset: CryptoCurrency = .bitcoin

    var defaultAccount: AnyPublisher<SingleAccount, CryptoAssetError> {
        repository.defaultAccount
            .mapError(CryptoAssetError.failedToLoadDefaultAccount)
            .map { account in
                BitcoinCryptoAccount(
                    walletAccount: account,
                    isDefault: true
                )
            }
            .eraseToAnyPublisher()
    }

    var canTransactToCustodial: AnyPublisher<Bool, Never> {
        cryptoAssetRepository.canTransactToCustodial
    }

    // MARK: - Private properties

    private lazy var cryptoAssetRepository: CryptoAssetRepositoryAPI = CryptoAssetRepository(
        asset: asset,
        errorRecorder: errorRecorder,
        kycTiersService: kycTiersService,
        defaultAccountProvider: { [defaultAccount] in
            defaultAccount
        },
        exchangeAccountsProvider: exchangeAccountProvider,
        addressFactory: addressFactory
    )

    private let addressFactory: ExternalAssetAddressFactory
    private let errorRecorder: ErrorRecording
    private let exchangeAccountProvider: ExchangeAccountsProviderAPI
    private let repository: BitcoinWalletAccountRepository
    private let kycTiersService: KYCTiersServiceAPI

    init(
        addressFactory: ExternalAssetAddressFactory = resolve(
            tag: BitcoinChainCoin.bitcoin
        ),
        errorRecorder: ErrorRecording = resolve(),
        exchangeAccountProvider: ExchangeAccountsProviderAPI = resolve(),
        kycTiersService: KYCTiersServiceAPI = resolve(),
        repository: BitcoinWalletAccountRepository = resolve()
    ) {
        self.addressFactory = addressFactory
        self.errorRecorder = errorRecorder
        self.exchangeAccountProvider = exchangeAccountProvider
        self.kycTiersService = kycTiersService
        self.repository = repository
    }

    // MARK: - Methods

    func initialize() -> AnyPublisher<Void, AssetError> {
        // Run wallet renaming procedure on initialization.
        cryptoAssetRepository
            .nonCustodialGroup
            .compactMap { $0 }
            .map(\.accounts)
            .flatMap { [upgradeLegacyLabels] accounts in
                upgradeLegacyLabels(accounts)
            }
            .mapError()
            .eraseToAnyPublisher()
    }

    func accountGroup(filter: AssetFilter) -> AnyPublisher<AccountGroup?, Never> {
        var groups: [AnyPublisher<AccountGroup?, Never>] = []

        if filter.contains(.custodial) {
            groups.append(custodialGroup)
        }

        if filter.contains(.interest) {
            groups.append(interestGroup)
        }

        if filter.contains(.nonCustodial) {
            groups.append(nonCustodialGroup)
        }

        if filter.contains(.exchange) {
            groups.append(exchangeGroup)
        }

        return groups
        .zip()
        .eraseToAnyPublisher()
        .flatMapAllAccountGroup()
    }

    func parse(address: String) -> AnyPublisher<ReceiveAddress?, Never> {
        cryptoAssetRepository.parse(address: address)
    }

    func parse(
        address: String,
        label: String,
        onTxCompleted: @escaping (TransactionResult) -> Completable
    ) -> Result<CryptoReceiveAddress, CryptoReceiveAddressFactoryError> {
        cryptoAssetRepository.parse(address: address, label: label, onTxCompleted: onTxCompleted)
    }

    // MARK: - Private methods

    private var allAccountsGroup: AnyPublisher<AccountGroup?, Never> {
        [
            nonCustodialGroup,
            custodialGroup,
            interestGroup,
            exchangeGroup
        ]
        .zip()
        .eraseToAnyPublisher()
        .flatMapAllAccountGroup()
    }

    private var exchangeGroup: AnyPublisher<AccountGroup?, Never> {
        cryptoAssetRepository.exchangeGroup
    }

    private var interestGroup: AnyPublisher<AccountGroup?, Never> {
        cryptoAssetRepository.interestGroup
    }

    private var custodialGroup: AnyPublisher<AccountGroup?, Never> {
        cryptoAssetRepository.custodialGroup
    }

    private var custodialAndInterestGroup: AnyPublisher<AccountGroup?, Never> {
        cryptoAssetRepository.custodialAndInterestGroup
    }

    private var nonCustodialGroup: AnyPublisher<AccountGroup?, Never> {
        repository.activeAccounts
            .eraseToAnyPublisher()
            .eraseError()
            .flatMap { [repository] accounts -> AnyPublisher<AccountsPayload, Error> in
                repository.defaultAccount
                    .map { .init(defaultAccount: $0, accounts: accounts) }
                    .eraseError()
                    .eraseToAnyPublisher()
            }
            .map { accountPayload -> [SingleAccount] in
                accountPayload.accounts.map { account in
                    BitcoinCryptoAccount(
                        walletAccount: account,
                        isDefault: account.publicKeys.default == accountPayload.defaultAccount.publicKeys.default
                    )
                }
            }
            .map { [asset] accounts -> AccountGroup? in
                if accounts.isEmpty {
                    return nil
                }
                return CryptoAccountNonCustodialGroup(asset: asset, accounts: accounts)
            }
            .recordErrors(on: errorRecorder)
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
}

extension BitcoinAsset: DomainResolutionRecordProviderAPI {

    var resolutionRecord: AnyPublisher<ResolutionRecord, Error> {
        resolutionRecordAccount
            .eraseError()
            .flatMap { account in
                account.firstReceiveAddress.eraseError()
            }
            .map { [asset] receiveAddress in
                ResolutionRecord(symbol: asset.code, walletAddress: receiveAddress.address)
            }
            .eraseToAnyPublisher()
    }

    private var resolutionRecordAccount: AnyPublisher<BitcoinCryptoAccount, BitcoinWalletRepositoryError> {
        repository
            .accounts
            .map { accounts -> BitcoinWalletAccount? in
                accounts.first(where: { $0.index == 0 })
            }
            .onNil(.missingWallet)
            .map { account in
                BitcoinCryptoAccount(
                    walletAccount: account,
                    isDefault: false
                )
            }
            .eraseToAnyPublisher()
    }
}
