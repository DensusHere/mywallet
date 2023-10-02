// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureTransactionDomain
import PlatformKit
import WalletPayloadKit

extension DependencyContainer {

    // MARK: - BitcoinChainKit Module

    public static var bitcoinChainKit = module {

        // MARK: - Bitcoin

        factory(tag: BitcoinChainCoin.bitcoin) {
            BitcoinChainKit.APIClient(coin: .bitcoin) as BitcoinChainKit.APIClientAPI
        }

        single(tag: BitcoinChainCoin.bitcoin) { () -> UnspentOutputRepositoryAPI in
            UnspentOutputRepository(
                client: DIKit.resolve(tag: BitcoinChainCoin.bitcoin),
                coin: BitcoinChainCoin.bitcoin,
                app: DIKit.resolve()
            )
        }

        factory(tag: BitcoinChainCoin.bitcoin) { () -> BitcoinTransactionSendingServiceAPI in
            BitcoinTransactionSendingService(
                client: DIKit.resolve(tag: BitcoinChainCoin.bitcoin)
            )
        }

        factory(tag: BitcoinChainCoin.bitcoin) {
            AnyCryptoFeeRepository<BitcoinChainTransactionFee<BitcoinToken>>.bitcoin()
        }

        factory(tag: BitcoinChainCoin.bitcoin) {
            BitcoinChainExternalAssetAddressFactory<BitcoinToken>() as ExternalAssetAddressFactory
        }

        factory(tag: AddressFactoryTag.bitcoin) {
            BitcoinChainExternalAssetAddressFactory<BitcoinToken>() as ExternalAssetAddressFactory
        }

        factory { CryptoFeeRepository<BitcoinChainTransactionFee<BitcoinToken>>() }

        factory(tag: BitcoinChainCoin.bitcoin) { () -> BitcoinChainTransactionBuildingServiceAPI in
            BitcoinChainTransactionBuildingService(
                unspentOutputRepository: DIKit.resolve(tag: BitcoinChainCoin.bitcoin),
                coinSelection: DIKit.resolve(),
                coin: .bitcoin
            )
        }

        single(tag: BitcoinChain.chainQueue) {
            DispatchQueue(label: "bitcoin.chain.receive.address.queue", qos: .userInitiated)
        }

        factory(tag: BitcoinChainCoin.bitcoin) { () -> BitcoinChainReceiveAddressProviderAPI in
            BitcoinChainReceiveAddressProvider<BitcoinToken>(
                mnemonicProvider: DIKit.resolve(),
                fetchMultiAddressFor: DIKit.resolve(tag: BitcoinChainCoin.bitcoin),
                unspentOutputRepository: DIKit.resolve(tag: BitcoinChainCoin.bitcoin),
                operationQueue: DIKit.resolve(tag: BitcoinChain.chainQueue)
            )
        }

        // MARK: - Bitcoin Cash

        factory(tag: BitcoinChainCoin.bitcoinCash) {
            BitcoinChainKit.APIClient(coin: .bitcoinCash) as BitcoinChainKit.APIClientAPI
        }

        single(tag: BitcoinChainCoin.bitcoinCash) { () -> UnspentOutputRepositoryAPI in
            UnspentOutputRepository(
                client: DIKit.resolve(tag: BitcoinChainCoin.bitcoinCash),
                coin: BitcoinChainCoin.bitcoinCash,
                app: DIKit.resolve()
            )
        }

        factory(tag: BitcoinChainCoin.bitcoinCash) { () -> BitcoinTransactionSendingServiceAPI in
            BitcoinTransactionSendingService(
                client: DIKit.resolve(tag: BitcoinChainCoin.bitcoinCash)
            )
        }

        factory(tag: BitcoinChainCoin.bitcoinCash) {
            AnyCryptoFeeRepository<BitcoinChainTransactionFee<BitcoinCashToken>>.bitcoinCash()
        }

        factory(tag: BitcoinChainCoin.bitcoinCash) {
            BitcoinChainExternalAssetAddressFactory<BitcoinCashToken>() as ExternalAssetAddressFactory
        }

        factory(tag: AddressFactoryTag.bitcoinCash) {
            BitcoinChainExternalAssetAddressFactory<BitcoinCashToken>() as ExternalAssetAddressFactory
        }

        factory { CryptoFeeRepository<BitcoinChainTransactionFee<BitcoinCashToken>>() }

        factory(tag: BitcoinChainCoin.bitcoinCash) { () -> BitcoinChainTransactionBuildingServiceAPI in
            BitcoinChainTransactionBuildingService(
                unspentOutputRepository: DIKit.resolve(tag: BitcoinChainCoin.bitcoinCash),
                coinSelection: DIKit.resolve(),
                coin: .bitcoinCash
            )
        }

        factory(tag: BitcoinChainCoin.bitcoinCash) { () -> BitcoinChainReceiveAddressProviderAPI in
            BitcoinChainReceiveAddressProvider<BitcoinCashToken>(
                mnemonicProvider: DIKit.resolve(),
                fetchMultiAddressFor: DIKit.resolve(tag: BitcoinChainCoin.bitcoinCash),
                unspentOutputRepository: DIKit.resolve(tag: BitcoinChainCoin.bitcoinCash),
                operationQueue: DIKit.resolve(tag: BitcoinChain.chainQueue)
            )
        }

        // MARK: - Asset Agnostic

        factory { CoinSelection() as CoinSelector }

        // MARK: - Sync PubKeys Address Providing

        factory { () -> SyncPubKeysAddressesProviderAPI in
            SyncPubKeysAddressesProvider(
                addressProvider: DIKit.resolve(tag: BitcoinChainCoin.bitcoin),
                fetchMultiAddressFor: DIKit.resolve(tag: BitcoinChainCoin.bitcoin)
            )
        }

        // MARK: - Sweep Imported Addresses

        single { () -> SweepImportedAddressesRepositoryAPI in
            SweepImportedAddressesRepository(app: DIKit.resolve())
        }

        single { () -> SweepImportedAddressesServiceAPI in
            let coincore: CoincoreAPI = DIKit.resolve()
            let btcCandidateProvider = TransactionCandidateProvider<BitcoinToken>(buildService: DIKit.resolve(tag: BitcoinChainCoin.bitcoin))
            let bchCandidateProvider = TransactionCandidateProvider<BitcoinCashToken>(buildService: DIKit.resolve(tag: BitcoinChainCoin.bitcoinCash))
            let defaultAccountProvider = defaultAccountProvider(coincore: coincore)
            let importedAddressesProvider = importedAddressesProvider(
                coincore: coincore,
                btcCandidateProvider: btcCandidateProvider,
                bchCandidateProvider: bchCandidateProvider,
                dispatchQueue: DispatchQueue(label: "addresses.provider", qos: .default),
                defaultAccountProvider: defaultAccountProvider
            )
            return SweepImportedAddressesService(
                sweptBalancesRepository: DIKit.resolve(),
                btcAddressProvider: DIKit.resolve(tag: BitcoinChainCoin.bitcoin),
                bchAddressProvider: DIKit.resolve(tag: BitcoinChainCoin.bitcoinCash),
                btcFetchMultiAddrFor: DIKit.resolve(tag: BitcoinChainCoin.bitcoin),
                bchFetchMultiAddrFor: DIKit.resolve(tag: BitcoinChainCoin.bitcoinCash),
                importedAddresses: importedAddressesProvider,
                defaultAccount: defaultAccountProvider,
                doPerformSweep: doPerformSweep
            )
        }
    }
}

extension AnyCryptoFeeRepository where FeeType == BitcoinChainTransactionFee<BitcoinToken> {
    fileprivate static func bitcoin(
        repository: CryptoFeeRepository<BitcoinChainTransactionFee<BitcoinToken>> = resolve()
    ) -> AnyCryptoFeeRepository<FeeType> {
        AnyCryptoFeeRepository<FeeType>(repository: repository)
    }
}

extension AnyCryptoFeeRepository where FeeType == BitcoinChainTransactionFee<BitcoinCashToken> {
    fileprivate static func bitcoinCash(
        repository: CryptoFeeRepository<BitcoinChainTransactionFee<BitcoinCashToken>> = resolve()
    ) -> AnyCryptoFeeRepository<FeeType> {
        AnyCryptoFeeRepository<FeeType>(repository: repository)
    }
}
