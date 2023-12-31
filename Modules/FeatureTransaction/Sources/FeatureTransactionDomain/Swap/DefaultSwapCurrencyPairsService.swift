// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Foundation
import MoneyKit
import PlatformKit

public struct SelectionInformation: Equatable {
    public init(accountId: String, currency: CryptoCurrency) {
        self.accountId = accountId
        self.currency = currency
    }

    public var accountId: String
    public var currency: CryptoCurrency
}

public protocol DefaultSwapCurrencyPairsServiceAPI {
    func getDefaultPairs(sourceInformation: SelectionInformation?, targetInformation: SelectionInformation?) async -> (source: SelectionInformation, target: SelectionInformation)?
}

public class DefaultSwapCurrencyPairsService: DefaultSwapCurrencyPairsServiceAPI {
    private let app: AppProtocol
    private let supportedPairsInteractorService: SupportedPairsInteractorServiceAPI

    public init(
        app: AppProtocol,
        supportedPairsInteractorService: SupportedPairsInteractorServiceAPI
    ) {
        self.app = app
        self.supportedPairsInteractorService = supportedPairsInteractorService
    }

    public func getDefaultPairs(
        sourceInformation: SelectionInformation?,
        targetInformation: SelectionInformation?
    ) async -> (source: SelectionInformation, target: SelectionInformation)? {
        let appMode = await app.mode()

        switch appMode {
        case .trading:
            return await getDefaultTradingPairs(
                sourceInformation: sourceInformation,
                targetInformation: targetInformation
            )
        case .pkw:
            return await getDefaultNonCustodialPairs(
                sourceInformation: sourceInformation,
                targetInformation: targetInformation
            )
        }
    }

    private func getDefaultTradingPairs(
        sourceInformation: SelectionInformation? = nil,
        targetInformation: SelectionInformation? = nil
    ) async -> (source: SelectionInformation, target: SelectionInformation)? {
        do {
            let tradableCurrencies = try await supportedPairsInteractorService
                .fetchSupportedTradingCryptoCurrencies()
                .await()
                .map(\.code)

            let tradingPairs = try await app.get(blockchain.api.nabu.gateway.trading.swap.pairs, as: [TradingPair].self)

            let custodialCurrencies = try await app.get(blockchain.user.trading.currencies, as: [String].self)
            let allBalances = try await custodialCurrencies
                .async
                .filter { tradableCurrencies.contains($0) }
                .map { currency -> MoneyValuePair in
                    try await MoneyValuePair(
                        base: self.app.get(blockchain.user.trading.account[currency].balance.available),
                        exchangeRate: self.app.get(blockchain.api.nabu.gateway.price.at.time[PriceTime.now.id].crypto[currency].fiat.quote.value)
                    )
                }
                .reduce(into: []) { balances, moneyValuePair in
                    balances.append(moneyValuePair)
                }
                .sorted(by: { try $0.quote > $1.quote })

            let firstBalance = try firstValidBalance(
                targetCurrency: targetInformation?.currency.currencyType,
                tradingPairs: tradingPairs,
                allBalances: allBalances
            )
                .or(throw: "No matching pairs")

            let firstBalanceAccountId = try? await app
                .get(blockchain.coin.core.accounts.custodial.asset[firstBalance.base.currency.code], as: String.self)

            let bitcoinAccountId = try? await app
                .get(blockchain.coin.core.accounts.custodial.asset[CryptoCurrency.bitcoin.code], as: String.self)
            let usdtAccountId = try? await app
                .get(blockchain.coin.core.accounts.custodial.asset["USDT"], as: String.self)

            switch (sourceInformation, targetInformation) {
            case (nil, nil):
                return try pairForSource(
                    with: firstBalance.base.currency,
                    accountId: firstBalanceAccountId,
                    usdtAccountId: usdtAccountId,
                    bitcoinAccountId: bitcoinAccountId
                )
            case (let source, nil):
                return try pairForSource(
                    with: sourceInformation?.currency.currencyType ?? firstBalance.base.currency,
                    accountId: source?.accountId ?? firstBalanceAccountId,
                    usdtAccountId: usdtAccountId,
                    bitcoinAccountId: bitcoinAccountId
                )

            case (nil, let target):
                if let target {
                    if let firstBalanceAccountId,
                       let firstBalanceCurrency = firstBalance.base.currency.cryptoCurrency
                    {
                        let source = SelectionInformation(
                            accountId: firstBalanceAccountId,
                            currency: firstBalanceCurrency
                        )
                        return (source: source, target: target)
                    }
                }
                return nil

            default:
                return nil
            }
        } catch {
            return nil
        }
    }

    private func getDefaultNonCustodialPairs(
        sourceInformation: SelectionInformation? = nil,
        targetInformation: SelectionInformation? = nil
    ) async -> (source: SelectionInformation, target: SelectionInformation)? {
        do {
            let tradingCurrencies = try await supportedPairsInteractorService
                .fetchSupportedTradingCryptoCurrencies()
                .await()
                .map(\.code)

            let tradingPairs = try await app.get(blockchain.api.nabu.gateway.trading.swap.pairs, as: [TradingPair].self)
            let nonCustodialCurrencies = try await app.get(blockchain.user.pkw.currencies, as: [String].self)
            let allBalances = try await nonCustodialCurrencies
                .async
                .filter { tradingCurrencies.contains($0) }
                .map { currency -> MoneyValuePair in
                    try await MoneyValuePair(
                        base: self.app.get(blockchain.user.pkw.asset[currency].balance),
                        exchangeRate: self.app.get(blockchain.api.nabu.gateway.price.at.time[PriceTime.now.id].crypto[currency].fiat.quote.value)
                    )
                }
                .reduce(into: []) { balances, moneyValuePair in
                    balances.append(moneyValuePair)
                }
                .sorted(by: { try $0.quote > $1.quote })

            let firstBalance = try firstValidBalance(
                targetCurrency: targetInformation?.currency.currencyType,
                tradingPairs: tradingPairs,
                allBalances: allBalances
            )
                .or(throw: "No matching pairs")

            let firstBalanceAccountId: String? = try? await app
                .get(blockchain.coin.core.accounts.DeFi.asset[firstBalance.base.currency.code], as: [String].self)
                .first
            let bitcoinAccountId: String? = try? await app
                .get(blockchain.coin.core.accounts.DeFi.asset[CryptoCurrency.bitcoin.code], as: [String].self)
                .first
            let usdtAccountId: String? = try? await app
                .get(blockchain.coin.core.accounts.DeFi.asset["USDT"], as: [String].self)
                .first

            switch (sourceInformation, targetInformation) {
            case (nil, nil):
                return try pairForSource(
                    with: firstBalance.base.currency,
                    accountId: firstBalanceAccountId,
                    usdtAccountId: usdtAccountId,
                    bitcoinAccountId: bitcoinAccountId
                )
            case (let source, nil):
                return try pairForSource(
                    with: sourceInformation?.currency.currencyType ?? firstBalance.base.currency,
                    accountId: source?.accountId ?? firstBalanceAccountId,
                    usdtAccountId: usdtAccountId,
                    bitcoinAccountId: bitcoinAccountId
                )

            case (nil, let target):
                if let target {
                    if let firstBalanceAccountId,
                       let firstBalanceCurrency = firstBalance.base.currency.cryptoCurrency
                    {
                        let source = SelectionInformation(
                            accountId: firstBalanceAccountId,
                            currency: firstBalanceCurrency
                        )
                        return (source: source, target: target)
                    }
                }
                return nil

            default:
                return nil
            }
        } catch {
            return nil
        }
    }

    private func firstValidBalance(
        targetCurrency: CurrencyType?,
        tradingPairs: [TradingPair],
        allBalances: [MoneyValuePair]
    ) -> MoneyValuePair? {
        guard let targetCurrency else {
            return allBalances.first
        }
        let firstBalance = allBalances
            .first { balance in
                tradingPairs.contains { pair in
                    pair.sourceCurrencyType == balance.base.currency && pair.destinationCurrencyType == targetCurrency
                }
            }
        return firstBalance
    }

    private func pairForSource(
        with currency: CurrencyType,
        accountId: String?,
        usdtAccountId: String?,
        bitcoinAccountId: String?,
        currenciesService: EnabledCurrenciesServiceAPI = EnabledCurrenciesService.default
    ) throws -> (source: SelectionInformation, target: SelectionInformation) {
        guard let cryptoCurrency = currency.cryptoCurrency else {
            throw "Not a cryptocurrency"
        }
        guard let accountId else {
            throw "No account id found"
        }
        let bitcoin = CryptoCurrency.bitcoin
        let source = SelectionInformation(accountId: accountId, currency: cryptoCurrency)
        let destination: SelectionInformation

        // If source is Bitcoin
        if cryptoCurrency == bitcoin {
            // Then target will be USDT
            let usdtAccountId = try usdtAccountId.or(throw: "No USDT account id found")
            let usdt = try currenciesService
                .allEnabledCryptoCurrencies
                .first(where: { $0.code == "USDT" })
                .or(throw: "No USDT found")
            destination = SelectionInformation(accountId: usdtAccountId, currency: usdt)
        } else {
            // Else target will be Bitcoin
            let bitcoinAccountId = try bitcoinAccountId.or(throw: "No BTC account id found")
            destination = SelectionInformation(accountId: bitcoinAccountId, currency: bitcoin)
        }
        return (source: source, target: destination)
    }
}
