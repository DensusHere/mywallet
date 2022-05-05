// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import RxSwift
import ToolKit

// swiftformat:disable all

/// A type that represents a payment method as a `BlockchainAccount`.
public final class PaymentMethodAccount: FiatAccount {

    public let paymentMethodType: PaymentMethodType
    public let paymentMethod: PaymentMethod
    public let priceService: PriceServiceAPI
    public let accountType: AccountType

    public init(
        paymentMethodType: PaymentMethodType,
        paymentMethod: PaymentMethod,
        priceService: PriceServiceAPI = resolve()
    ) {
        self.paymentMethodType = paymentMethodType
        self.paymentMethod = paymentMethod
        self.priceService = priceService
        accountType = paymentMethod.isCustodial ? .custodial : .nonCustodial
    }

    public let isDefault: Bool = false

    public var activity: Single<[ActivityItemEvent]> {
        .just([]) // no activity to report
    }

    public var fiatCurrency: FiatCurrency {
        guard let fiatCurrency = paymentMethodType.currency.fiatCurrency else {
            impossible("Payment Method Accounts should always be denominated in fiat.")
        }
        return fiatCurrency
    }

    public var canWithdrawFunds: Single<Bool> {
        .just(false)
    }

    public var identifier: AnyHashable {
        paymentMethodType.id
    }

    public var label: String {
        paymentMethodType.label
    }

    public var isFunded: Single<Bool> {
        .just(true)
    }

    public var balance: Single<MoneyValue> {
        .just(paymentMethodType.balance)
    }

    public func can(perform action: AssetAction) -> AnyPublisher<Bool, Error>{
        .just(action == .buy)
    }

    public var pendingBalance: Single<MoneyValue> {
        balance
    }

    public var actionableBalance: Single<MoneyValue> {
        balance
    }

    public var receiveAddress: Single<ReceiveAddress> {
        .error(ReceiveAddressError.notSupported)
    }

    public func balancePair(fiatCurrency: FiatCurrency, at time: PriceTime) -> AnyPublisher<MoneyValuePair, Error> {
        priceService
            .price(of: self.fiatCurrency, in: fiatCurrency, at: time)
            .eraseError()
            .zip(balancePublisher)
            .tryMap { fiatPrice, balance in
                MoneyValuePair(base: balance, exchangeRate: fiatPrice.moneyValue)
            }
            .eraseToAnyPublisher()
    }

    public func invalidateAccountBalance() {
        // NO-OP
    }
}