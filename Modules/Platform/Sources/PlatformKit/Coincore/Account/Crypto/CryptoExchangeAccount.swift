// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import RxSwift
import ToolKit

/// State of Exchange account linking
public enum ExchangeAccountState: String {
    case pending = "PENDING"
    case active = "ACTIVE"
    case blocked = "BLOCKED"

    /// Returns `true` for an active state
    public var isActive: Bool {
        switch self {
        case .active:
            return true
        case .pending, .blocked:
            return false
        }
    }

    // MARK: - Init

    init(state: CryptoExchangeAddressResponse.State) {
        switch state {
        case .active:
            self = .active
        case .blocked:
            self = .blocked
        case .pending:
            self = .pending
        }
    }
}

public protocol ExchangeAccount: CryptoAccount {
    var state: ExchangeAccountState { get }
}

public final class CryptoExchangeAccount: ExchangeAccount {

    public var accountType: AccountType = .exchange

    public var actionableBalance: AnyPublisher<MoneyValue, Error> {
        .just(.zero(currency: asset))
    }

    public var balance: AnyPublisher<MoneyValue, Error> {
        .just(.zero(currency: asset))
    }

    public var receiveAddress: AnyPublisher<ReceiveAddress, Error> {
        cryptoReceiveAddressFactory
            .makeExternalAssetAddress(
                address: address,
                label: label,
                onTxCompleted: onTxCompleted
            )
            .map { $0 as ReceiveAddress }
            .eraseError()
            .publisher
            .eraseToAnyPublisher()
    }

    public var pendingBalance: AnyPublisher<MoneyValue, Error> {
        /// Exchange API does not return a balance.
        .just(.zero(currency: asset))
    }

    public var isFunded: AnyPublisher<Bool, Error> {
        .just(true)
    }

    public var activity: AnyPublisher<[ActivityItemEvent], Error> {
        .just([])
    }

    public private(set) lazy var identifier: AnyHashable = "CryptoExchangeAccount." + asset.code
    public let asset: CryptoCurrency
    public let isDefault: Bool = false
    public let label: String
    public let state: ExchangeAccountState

    public func balancePair(
        fiatCurrency: FiatCurrency,
        at time: PriceTime
    ) -> AnyPublisher<MoneyValuePair, Error> {
        /// Exchange API does not return a balance.
        .just(.zero(baseCurrency: currencyType, quoteCurrency: fiatCurrency.currencyType))
    }

    public func invalidateAccountBalance() {
        // NO-OP
    }

    public func can(perform action: AssetAction) -> AnyPublisher<Bool, Error> {
        .just(false)
    }

    public let featureFlagsService: FeatureFlagsServiceAPI

    // MARK: - Private Properties

    private let address: String
    private let exchangeAccountProvider: ExchangeAccountsProviderAPI
    private let cryptoReceiveAddressFactory: ExternalAssetAddressFactory

    // MARK: - Init

    init(
        response: CryptoExchangeAddressResponse,
        featureFlagsService: FeatureFlagsServiceAPI = resolve(),
        exchangeAccountProvider: ExchangeAccountsProviderAPI = resolve(),
        cryptoReceiveAddressFactory: ExternalAssetAddressFactory
    ) {
        label = response.assetType.defaultExchangeWalletName
        asset = response.assetType
        address = response.address
        state = .init(state: response.state)
        self.featureFlagsService = featureFlagsService
        self.exchangeAccountProvider = exchangeAccountProvider
        self.cryptoReceiveAddressFactory = cryptoReceiveAddressFactory
    }
}
