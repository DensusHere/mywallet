// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Blockchain
import Combine
import FeatureDashboardDomain
import MoneyKit
import ToolKit

final class AssetBalanceInfoRepository: AssetBalanceInfoRepositoryAPI {

    @Dependency(\.app) var app

    private let service: AssetBalanceInfoServiceAPI

    init(service: AssetBalanceInfoServiceAPI) {
        self.service = service
    }

    func cryptoCustodial(fiatCurrency: FiatCurrency, time: PriceTime) -> StreamOf<[AssetBalanceInfo], Never> {
        service.getCustodialCryptoAssetsInfo(
            fiatCurrency: fiatCurrency,
            at: time
        )
        .result()
    }

    func fiat(fiatCurrency: FiatCurrency, time: PriceTime) -> StreamOf<[AssetBalanceInfo], Never> {
        service.getFiatAssetsInfo(
            fiatCurrency: fiatCurrency,
            at: time
        )
        .result()
    }

    func cryptoNonCustodial(fiatCurrency: FiatCurrency, time: PriceTime) -> StreamOf<[AssetBalanceInfo], Never> {
        service.getNonCustodialCryptoAssetsInfo(
            fiatCurrency: fiatCurrency,
            at: time
        )
        .result()
    }
}
