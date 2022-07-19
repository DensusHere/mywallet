// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import Foundation
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

/// A CryptoAccount, NonCustodialAccount object used by Receive screen to display currencies that are not yet currently loaded.
final class ReceivePlaceholderCryptoAccount: CryptoAccount, NonCustodialAccount {

    var asset: CryptoCurrency

    var isDefault: Bool = true

    var identifier: AnyHashable = UUID().uuidString

    let accountType: AccountType = .nonCustodial

    var balance: AnyPublisher<MoneyValue, Error> {
        .just(.zero(currency: asset))
    }

    var pendingBalance: AnyPublisher<MoneyValue, Error> {
        .just(.zero(currency: asset))
    }

    var actionableBalance: AnyPublisher<MoneyValue, Error> {
        .just(.zero(currency: asset))
    }

    var activity: AnyPublisher<[ActivityItemEvent], Error> {
        .just([])
    }

    func balancePair(
        fiatCurrency: FiatCurrency,
        at time: PriceTime
    ) -> AnyPublisher<MoneyValuePair, Error> {
        .just(.zero(baseCurrency: asset.currencyType, quoteCurrency: fiatCurrency.currencyType))
    }

    func can(perform action: AssetAction) -> AnyPublisher<Bool, Error> {
        .just(true)
    }

    var receiveAddress: AnyPublisher<ReceiveAddress, Error> {
        .failure(ReceiveAddressError.notSupported)
    }

    var requireSecondPassword: Single<Bool> {
        .just(false)
    }

    var label: String {
        asset.defaultWalletName
    }

    init(
        asset: CryptoCurrency
    ) {
        self.asset = asset
    }

    func invalidateAccountBalance() {
        // NO-OP
    }
}
