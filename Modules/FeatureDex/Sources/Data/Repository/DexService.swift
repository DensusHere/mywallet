// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Combine
import DelegatedSelfCustodyDomain
import Dependencies
import DIKit
import Errors
import FeatureDexDomain
import Foundation
import MoneyKit
import NetworkKit
import UnifiedActivityDomain

public struct DexService {

    @Dependency(\.transactionCreationService) var transactionCreationService
    @Dependency(\.dexAllowanceRepository) var dexAllowanceRepository

    public func executeTransaction(
        quote: DexQuoteOutput
    ) -> AnyPublisher<Result<String, UX.Error>, Never> {
        transactionCreationService
            .build(quote: quote)
            .flatMap { output in
                switch output {
                case .success(let success):
                    return transactionCreationService
                        .signAndPush(token: quote.sellAmount.currency, output: success)
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
            .eraseToAnyPublisher()
    }

    public func allowance(
        app: AppProtocol,
        currency: CryptoCurrency
    ) -> AnyPublisher<Result<DexAllowanceResult, UX.Error>, Never> {
        guard !currency.isCoin else {
            return .just(.success(.ok))
        }
        return receiveAddressProvider(app, currency)
            .optional()
            .replaceError(with: nil)
            .flatMap { address -> AnyPublisher<Result<DexAllowanceResult, UX.Error>, Never> in
                guard let address else {
                    return .just(.failure(UX.Error(error: nil)))
                }
                return allowance(address: address, currency: currency)
            }
            .eraseToAnyPublisher()
    }

    public func allowancePoll(
        app: AppProtocol,
        currency: CryptoCurrency
    ) -> AnyPublisher<Result<DexAllowanceResult, UX.Error>, Never> {
        guard !currency.isCoin else {
            return .just(.success(.ok))
        }
        return receiveAddressProvider(app, currency)
            .optional()
            .replaceError(with: nil)
            .flatMap { address -> AnyPublisher<Result<DexAllowanceResult, UX.Error>, Never> in
                guard let address else {
                    return .just(.failure(UX.Error(error: nil)))
                }
                return allowance(address: address, currency: currency)
            }
            .eraseToAnyPublisher()
    }

    private func allowance(
        address: String,
        currency: CryptoCurrency
    ) -> AnyPublisher<Result<DexAllowanceResult, UX.Error>, Never> {
        dexAllowanceRepository
            .fetch(address: address, currency: currency)
            .map { output -> DexAllowanceResult in
                output.isOK ? .ok : .nok
            }
            .mapError(UX.Error.init(error:))
            .result()
            .eraseToAnyPublisher()
    }

    private func allowancePoll(
        address: String,
        currency: CryptoCurrency
    ) -> AnyPublisher<Result<DexAllowanceResult, UX.Error>, Never> {
        dexAllowanceRepository
            .poll(address: address, currency: currency)
            .map { output -> DexAllowanceResult in
                output.isOK ? .ok : .nok
            }
            .mapError(UX.Error.init(error:))
            .result()
            .eraseToAnyPublisher()
    }

    public var balances: () -> AnyPublisher<Result<[DexBalance], UX.Error>, Never>
    public var quote: (DexQuoteInput) -> AnyPublisher<Result<DexQuoteOutput, UX.Error>, Never>
    public var receiveAddressProvider: (AppProtocol, CryptoCurrency) -> AnyPublisher<String, Error>
    public var supportedTokens: () -> AnyPublisher<Result<[CryptoCurrency], UX.Error>, Never>
    public var availableChains: () -> AnyPublisher<Result<[EVMNetwork], UX.Error>, Never>
    public var pendingActivity: (EVMNetwork) -> AnyPublisher<Bool, Never>
}

extension DexService: DependencyKey {
    public static var liveValue: DexService {
        DexService(
            balances: {
                let service: DelegatedCustodyBalanceRepositoryAPI = DIKit.resolve()
                return service
                    .balances
                    .map { balances in
                        dexBalances(balances)
                    }
                    .mapError(UX.Error.init(error:))
                    .result()
                    .eraseToAnyPublisher()
            },
            quote: { quoteInput in
                let service = DexQuoteRepository(
                    client: Client(
                        networkAdapter: DIKit.resolve(tag: DIKitContext.retail),
                        requestBuilder: DIKit.resolve(tag: DIKitContext.retail)
                    ),
                    currenciesService: DIKit.resolve()
                )
                return service.quote(input: quoteInput)
            },
            receiveAddressProvider: { app, cryptoCurrency in
                receiveAddress(
                    app: app,
                    cryptoCurrency: cryptoCurrency
                )
            },
            supportedTokens: {
                let service = EnabledCurrenciesService.default
                let supported = service.allEnabledCryptoCurrencies
                return .just(.success(supported))
            },
            availableChains: {
                let chainsService = AvailableChainsService(chainsClient: Client(
                    networkAdapter: DIKit.resolve(),
                    requestBuilder: DIKit.resolve(tag: DIKitContext.dex)
                ))

                return chainsService
                    .availableChains()
                    .map { chains -> [EVMNetwork] in
                        let currenciesService = EnabledCurrenciesService.default
                        return chains.compactMap { chain -> EVMNetwork? in
                            currenciesService
                                .allEnabledEVMNetworks
                                .first(where: { $0.networkConfig.chainID == chain.chainId })
                        }
                    }
                    .mapError(UX.Error.init(error:))
                    .result()
                    .eraseToAnyPublisher()
            },
            pendingActivity: { network -> AnyPublisher<Bool, Never> in
                let service: UnifiedActivityRepositoryAPI = DIKit.resolve()
                return service
                    .pendingActivity
                    .map { (activity: [ActivityEntry]) -> Bool in
                        activity.contains(where: { entry in
                            entry.network == network.networkConfig.networkTicker
                        })
                    }
                    .eraseToAnyPublisher()
            }
        )
    }

    public static var previewValue = DexService.preview
}

extension DexService {

    public static var preview: DexService {
        _ = App.preview
        let currencies = EnabledCurrenciesService
            .default
            .allEnabledCryptoCurrencies

        return DexService(
            balances: { .just(.success(dexBalances(.preview))) },
            quote: { input in
                    .just(.success(.preview(buy: input.destination, sell: input.amount)))
            },
            receiveAddressProvider: { _, _ in .just("0x00000000000000000000000000000000DEADBEEF") },
            supportedTokens: { .just(.success(currencies)) },
            availableChains: {
                .just(.success([EVMNetwork(networkConfig: .ethereum, nativeAsset: .ethereum)]))
            },
            pendingActivity: { _ in .just(true) }
        )
    }

    public func setup(_ body: (inout DexService) -> Void) -> DexService {
        var copy = self
        body(&copy)
        return copy
    }
}

extension DependencyValues {

    public var dexService: DexService {
        get { self[DexService.self] }
        set { self[DexService.self] = newValue }
    }
}

private func dexBalances(
    _ balances: DelegatedCustodyBalances
) -> [DexBalance] {
    balances.balances
        .filter(\.balance.isPositive)
        .compactMap(\.balance.cryptoValue)
        .map(DexBalance.init)
}

private func receiveAddress(
    app: AppProtocol,
    cryptoCurrency: CryptoCurrency
) -> AnyPublisher<String, Error> {
    accountId(app: app, cryptoCurrency: cryptoCurrency)
        .flatMap { [app] identifier in
            address(app: app, accoundId: identifier)
        }
        .eraseToAnyPublisher()
}

private func accountId(
    app: AppProtocol,
    cryptoCurrency: CryptoCurrency
) -> AnyPublisher<String, Error> {
    app
        .publisher(
            for: blockchain.coin.core.accounts.DeFi.asset[cryptoCurrency.code],
            as: [String].self
        )
        .first()
        .map { result -> String? in
            let value = result.value
            return value?.first
        }
        .setFailureType(to: Error.self)
        .onNil(QuoteError.noReceiveAddress)
        .eraseToAnyPublisher()
}

private func address(
    app: AppProtocol,
    accoundId: String
) -> AnyPublisher<String, Error> {
    app
        .publisher(
            for: blockchain.coin.core.account[accoundId].receive.address,
            as: L_blockchain_coin_core_account_receive.JSON.self
        )
        .first()
        .map { result -> String? in
            let value = result.value
            return value?.address
        }
        .setFailureType(to: Error.self)
        .onNil(QuoteError.noReceiveAddress)
        .eraseToAnyPublisher()
}
