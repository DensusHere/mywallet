// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureTransactionDomain
import PlatformKit

extension DependencyContainer {

    // MARK: - BitcoinChainKit Module

    public static var bitcoinChainKit = module {

        // MARK: - Bitcoin

        factory(tag: BitcoinChainCoin.bitcoin) {
            BitcoinChainKit.APIClient(coin: .bitcoin) as BitcoinChainKit.APIClientAPI
        }

        factory(tag: BitcoinChainCoin.bitcoin) { () -> UnspentOutputRepositoryAPI in
            UnspentOutputRepository(
                client: DIKit.resolve(tag: BitcoinChainCoin.bitcoin),
                coin: BitcoinChainCoin.bitcoin
            )
        }

        factory(tag: BitcoinChainCoin.bitcoin) { () -> BitcoinTransactionSendingServiceAPI in
            BitcoinTransactionSendingService(
                client: DIKit.resolve(tag: BitcoinChainCoin.bitcoin)
            )
        }

        single(tag: BitcoinChainCoin.bitcoin) { BalanceService(coin: .bitcoin) as BalanceServiceAPI }

        factory(tag: BitcoinChainCoin.bitcoin) {
            AnyCryptoFeeRepository<BitcoinChainTransactionFee<BitcoinToken>>.bitcoin()
        }

        factory(tag: BitcoinChainCoin.bitcoin) {
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

        // MARK: - Bitcoin Cash

        factory(tag: BitcoinChainCoin.bitcoinCash) {
            BitcoinChainKit.APIClient(coin: .bitcoinCash) as BitcoinChainKit.APIClientAPI
        }

        factory(tag: BitcoinChainCoin.bitcoinCash) { () -> UnspentOutputRepositoryAPI in
            UnspentOutputRepository(
                client: DIKit.resolve(tag: BitcoinChainCoin.bitcoinCash),
                coin: BitcoinChainCoin.bitcoinCash
            )
        }

        factory(tag: BitcoinChainCoin.bitcoinCash) { () -> BitcoinTransactionSendingServiceAPI in
            BitcoinTransactionSendingService(
                client: DIKit.resolve(tag: BitcoinChainCoin.bitcoinCash)
            )
        }

        single(tag: BitcoinChainCoin.bitcoinCash) { BalanceService(coin: .bitcoinCash) as BalanceServiceAPI }

        factory(tag: BitcoinChainCoin.bitcoinCash) {
            AnyCryptoFeeRepository<BitcoinChainTransactionFee<BitcoinCashToken>>.bitcoinCash()
        }

        factory(tag: BitcoinChainCoin.bitcoinCash) {
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

        // MARK: - Asset Agnostic

        factory { CoinSelection() as CoinSelector }
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
