// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import RxSwift

public protocol FiatAccount: SingleAccount {
    var fiatCurrency: FiatCurrency { get }
    var canWithdrawFunds: Single<Bool> { get }
}

extension FiatAccount {

    public var currencyType: CurrencyType {
        fiatCurrency.currencyType
    }

    public var requireSecondPassword: Single<Bool> {
        .just(false)
    }
}
