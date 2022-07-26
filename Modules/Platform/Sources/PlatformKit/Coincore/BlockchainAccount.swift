// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import MoneyKit
import RxSwift
import ToolKit

public typealias AvailableActions = Set<AssetAction>

public protocol TradingAccount {}

public protocol BankAccount {}

public protocol NonCustodialAccount {}

public protocol InterestAccount {}

public protocol BlockchainAccount: Account {

    /// A unique identifier for this `BlockchainAccount`.
    ///
    /// This may be used to compare if two BlockchainAccount are the same.
    var identifier: AnyHashable { get }

    /// Emits `Set` containing all actions this account can execute.
    var actions: AnyPublisher<AvailableActions, Error> { get }

    var activity: AnyPublisher<[ActivityItemEvent], Error> { get }

    /// The reason why the BlockchainAccount is ineligible for Interest.
    /// This will be `.eligible` if the account is eligible
    var disabledReason: AnyPublisher<InterestAccountIneligibilityReason, Error> { get }

    /// Checks if this account can execute the given action.
    ///
    /// You should implement this method so it consumes the lesser amount of remote resources as possible.
    func can(perform action: AssetAction) -> AnyPublisher<Bool, Error>

    /// The `ReceiveAddress` for the given account
    var receiveAddress: AnyPublisher<ReceiveAddress, Error> { get }

    /// The first `ReceiveAddress` for the given first account (only for BTC and BCH)
    var firstReceiveAddress: AnyPublisher<ReceiveAddress, Error> { get }

    /// Some wallets are double encrypted and have a second password.
    var requireSecondPassword: Single<Bool> { get }

    // MARK: Balance

    /// The total balance on this account.
    var balance: AnyPublisher<MoneyValue, Error> { get }

    /// The pending balance of this account.
    var pendingBalance: AnyPublisher<MoneyValue, Error> { get }

    /// The balance, not including uncleared and locked,
    /// that the user is able to utilize in a transaction
    var actionableBalance: AnyPublisher<MoneyValue, Error> { get }

    /// Indicates if this account is funded.
    ///
    /// Depending of the account implementation, this may not strictly mean a positive balance.
    /// Some accounts may be set as `isFunded` if they have ever had a positive balance in the past.
    var isFunded: AnyPublisher<Bool, Error> { get }

    /// The balance of this account exchanged to the given fiat currency.
    func fiatBalance(fiatCurrency: FiatCurrency) -> AnyPublisher<MoneyValue, Error>

    /// The balance of this account exchanged to the given fiat currency.
    func fiatBalance(fiatCurrency: FiatCurrency, at time: PriceTime) -> AnyPublisher<MoneyValue, Error>

    /// The balance of this account exchanged to the given fiat currency.
    func balancePair(fiatCurrency: FiatCurrency) -> AnyPublisher<MoneyValuePair, Error>

    /// The balance of this account exchanged to the given fiat currency.
    func balancePair(fiatCurrency: FiatCurrency, at time: PriceTime) -> AnyPublisher<MoneyValuePair, Error>

    /// Various `BlockchainAccount` objects fetch their balance in
    /// different ways and use different services. After completing
    /// a transaction we may not want to fetch the balance but do want
    /// fetches anytime after the transaction to reflect the true balance
    /// of the account. All accounts have a 60 second cache but sometimes
    /// this cache should be invalidated.
    func invalidateAccountBalance()
}

extension BlockchainAccount {

    public var firstReceiveAddress: AnyPublisher<ReceiveAddress, Error> {
        receiveAddress
    }

    /// Account balance is positive.
    public var isFunded: AnyPublisher<Bool, Error> {
        balance
            .map(\.isPositive)
            .eraseToAnyPublisher()
    }

    public var hasPositiveDisplayableBalance: AnyPublisher<Bool, Error> {
        balance
            .map(\.hasPositiveDisplayableBalance)
            .eraseToAnyPublisher()
    }

    public var actions: AnyPublisher<AvailableActions, Error> {
        AssetAction.allCases
            .map { action in
                can(perform: action)
                    .map { canPerform in
                        (action: action, canPerform: canPerform)
                    }
            }
            .merge()
            .collect()
            .map { actions -> [AssetAction] in
                actions
                    .filter(\.canPerform)
                    .map(\.action)
            }
            .map(AvailableActions.init)
            .eraseToAnyPublisher()
    }

    public var disabledReason: AnyPublisher<InterestAccountIneligibilityReason, Error> {
        .just(.eligible)
    }

    public func balancePair(fiatCurrency: FiatCurrency) -> AnyPublisher<MoneyValuePair, Error> {
        balancePair(fiatCurrency: fiatCurrency, at: .now)
    }

    public func fiatBalance(fiatCurrency: FiatCurrency) -> AnyPublisher<MoneyValue, Error> {
        fiatBalance(fiatCurrency: fiatCurrency, at: .now)
    }

    public func fiatBalance(fiatCurrency: FiatCurrency, at time: PriceTime) -> AnyPublisher<MoneyValue, Error> {
        balancePair(fiatCurrency: fiatCurrency, at: time)
            .map(\.quote)
            .eraseToAnyPublisher()
    }

    public func balancePair(
        priceService: PriceServiceAPI,
        fiatCurrency: FiatCurrency,
        at time: PriceTime
    ) -> AnyPublisher<MoneyValuePair, Error> {
        priceService
            .price(of: currencyType, in: fiatCurrency, at: time)
            .eraseError()
            .zip(balance)
            .tryMap { fiatPrice, balance in
                MoneyValuePair(base: balance, exchangeRate: fiatPrice.moneyValue)
            }
            .eraseToAnyPublisher()
    }
}

extension Publisher where Output == [SingleAccount] {

    /// Maps each `[SingleAccount]` object filtering out accounts that match the given `BlockchainAccount` identifier.
    public func mapFilter(excluding identifier: AnyHashable) -> AnyPublisher<Output, Failure> {
        map { accounts in
            accounts.filter { $0.identifier != identifier }
        }
        .eraseToAnyPublisher()
    }
}
