// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BitcoinChainKit
import Combine
import DelegatedSelfCustodyDomain
import DIKit
import FeatureCryptoDomainDomain
import MoneyKit
import PlatformKit
import ToolKit

final class BitcoinAsset: CryptoAsset, SubscriptionEntriesAsset {

    let asset: CryptoCurrency = .bitcoin

    var defaultAccount: AnyPublisher<SingleAccount, CryptoAssetError> {
        repository.defaultAccount
            .map { account in
                BitcoinCryptoAccount(
                    walletAccount: account,
                    isDefault: true
                )
            }
            .mapError(CryptoAssetError.failedToLoadDefaultAccount)
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
        nonCustodialAccountsProvider: { [nonCustodialAccounts] in
            nonCustodialAccounts
        },
        importedAddressesAccountsProvider: { [importedAddresses] in
            importedAddresses
        },
        exchangeAccountsProvider: exchangeAccountProvider,
        addressFactory: addressFactory
    )

    let addressFactory: ExternalAssetAddressFactory

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
        nonCustodialAccounts
            .replaceError(with: [])
            .map { (accounts: [SingleAccount]) -> [BitcoinChainCryptoAccount] in
                accounts
                    .compactMap { (account: SingleAccount) -> BitcoinChainCryptoAccount? in
                        account as? BitcoinChainCryptoAccount
                    }
                    .filter { (account: BitcoinChainCryptoAccount) -> Bool in
                        account.labelNeedsForcedUpdate
                    }
            }
            .flatMap { [repository] accounts -> AnyPublisher<Void, Never> in
                guard accounts.isNotEmpty else {
                    return .just(())
                }
                return repository.updateLabels(on: accounts)
                    .eraseToAnyPublisher()
            }
            .mapError()
            .eraseToAnyPublisher()
    }

    var subscriptionEntries: AnyPublisher<[SubscriptionEntry], Never> {
        repository.activeAccounts
            .replaceError(with: [])
            .map { [asset] accounts -> [SubscriptionEntry] in
                accounts.map { account in
                    SubscriptionEntry(
                        account: SubscriptionEntry.Account(
                            index: account.index,
                            name: account.label
                        ),
                        currency: asset.code,
                        pubKeys: account.xpubs.map { xpub -> SubscriptionEntry.PubKey in
                            SubscriptionEntry.PubKey(
                                pubKey: xpub.address,
                                style: "EXTENDED",
                                descriptor: xpub.derivationType.isSegwit ? 1 : 0
                            )
                        }
                    )
                }
            }
            .eraseToAnyPublisher()
    }

    func accountGroup(filter: AssetFilter) -> AnyPublisher<AccountGroup?, Never> {
        cryptoAssetRepository.accountGroup(filter: filter)
    }

    func parse(address: String, memo: String?) -> AnyPublisher<ReceiveAddress?, Never> {
        cryptoAssetRepository.parse(address: address, memo: memo)
    }

    func parse(
        address: String,
        memo: String?,
        label: String,
        onTxCompleted: @escaping (TransactionResult) -> AnyPublisher<Void, Error>
    ) -> Result<CryptoReceiveAddress, CryptoReceiveAddressFactoryError> {
        cryptoAssetRepository.parse(address: address, memo: memo, label: label, onTxCompleted: onTxCompleted)
    }

    private var nonCustodialAccounts: AnyPublisher<[SingleAccount], CryptoAssetError> {
        repository.activeAccounts
            .zip(repository.defaultAccount)
            .map { activeAccounts, defaultAccount -> [SingleAccount] in
                activeAccounts.map { account in
                    BitcoinCryptoAccount(
                        walletAccount: account,
                        isDefault: account.defaultXPub == defaultAccount.defaultXPub
                    )
                }
            }
            .recordErrors(on: errorRecorder)
            .replaceError(with: CryptoAssetError.noDefaultAccount)
            .eraseToAnyPublisher()
    }

    private var importedAddresses: AnyPublisher<[SingleAccount], CryptoAssetError> {
        repository.importedAccounts
            .map { accounts -> [SingleAccount] in
                accounts.map { account in
                    BitcoinCryptoAccount(
                        walletAccount: account,
                        isDefault: false
                    )
                }
            }
            .recordErrors(on: errorRecorder)
            .replaceError(with: CryptoAssetError.noDefaultAccount)
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
