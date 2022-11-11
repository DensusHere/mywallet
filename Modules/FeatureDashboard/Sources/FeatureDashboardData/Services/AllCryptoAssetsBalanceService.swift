// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Combine
import CombineExtensions
import DelegatedSelfCustodyDomain
import FeatureDashboardDomain
import Foundation
import MoneyKit
import PlatformKit
import ToolKit

public class AllCryptoAssetsBalanceService: AllCryptoAssetsServiceAPI {
    private let custodialBalanceRepository: CustodialAssetsRepositoryAPI
    private let nonCustodialBalanceRepository: DelegatedCustodyBalanceRepositoryAPI
    private let fiatCurrencyService: FiatCurrencyServiceAPI
    private let coincore: CoincoreAPI
    private let priceService: PriceServiceAPI
    private let app: AppProtocol

    public init(
        allCrypoBalanceRepository: CustodialAssetsRepositoryAPI,
        nonCustodialBalanceRepository: DelegatedCustodyBalanceRepositoryAPI,
        priceService: PriceServiceAPI,
        fiatCurrencyService: FiatCurrencyServiceAPI,
        coincore: CoincoreAPI,
        app: AppProtocol
    ) {
        self.priceService = priceService
        self.fiatCurrencyService = fiatCurrencyService
        custodialBalanceRepository = allCrypoBalanceRepository
        self.nonCustodialBalanceRepository = nonCustodialBalanceRepository
        self.coincore = coincore
        self.app = app
    }

    public func getAllCryptoAssetsInfo() async -> [AssetBalanceInfo] {
        (try? await custodialBalanceRepository.assetsInfo.await()) ?? []
    }

    public func getFiatAssetsInfo() async -> AssetBalanceInfo? {
        let asset = coincore.fiatAsset
        if let accountGroup = try? await asset.accountGroup(filter: .all).await(),
           let fiatCurrency = try? await fiatCurrencyService.displayCurrency.await(),
           let account = accountGroup.accounts.first(where: { account in
               account.currencyType.fiatCurrency == fiatCurrency
           }),
           let balance = try? await account.balance.await()
        {

            let fiatBalance = try? await account.balancePair(fiatCurrency: fiatCurrency).await()

            return AssetBalanceInfo(
                cryptoBalance: balance,
                fiatBalance: fiatBalance,
                currency: account.currencyType,
                delta: nil
            )
        }
        return nil
    }

    public func getAllNonCustodialAssets() async -> [AssetBalanceInfo] {
        var assetsInfo: [AssetBalanceInfo] = []
        if let balanceInfo = try? await nonCustodialBalanceRepository.balances.await() {
            for balance in balanceInfo.balances {
                async let fiatCurrency = try? await fiatCurrencyService.currency.await()
                let currencyType = balance.balance.currencyType
                if let cryptoCurrency = currencyType.cryptoCurrency,
                   let fiatCurrency = await fiatCurrency,
                   let fiatBalance = try? await priceService
                    .price(of: cryptoCurrency, in: fiatCurrency, at: .now)
                    .await()
                {

                    assetsInfo.append(AssetBalanceInfo(
                        cryptoBalance: balance.balance,
                        fiatBalance: MoneyValuePair(base: balance.balance, exchangeRate: fiatBalance.moneyValue),
                        currency: currencyType,
                        delta: nil
                    ))
                }
            }
        }

        return assetsInfo
    }
}
