// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import Localization
import MoneyKit
import RxSwift
import ToolKit

public final class CryptoInterestAccount: CryptoAccount, InterestAccount {

    private enum CryptoInterestAccountError: LocalizedError {
        case loadingFailed(asset: String, label: String, action: AssetAction, error: String)

        var errorDescription: String? {
            switch self {
            case .loadingFailed(let asset, let label, let action, let error):
                return "Failed to load: 'CryptoInterestAccount' asset '\(asset)' label '\(label)' action '\(action)' error '\(error)' ."
            }
        }
    }

    public private(set) lazy var identifier: AnyHashable = "CryptoInterestAccount." + asset.code
    public let label: String
    public let asset: CryptoCurrency
    public let isDefault: Bool = false
    public var accountType: AccountType = .custodial

    public var receiveAddress: Single<ReceiveAddress> {
        receiveAddressRepository
            .fetchInterestAccountReceiveAddressForCurrencyCode(asset.code)
            .eraseToAnyPublisher()
            .asSingle()
            .flatMap { [cryptoReceiveAddressFactory, onTxCompleted, asset] addressString in
                cryptoReceiveAddressFactory
                    .makeExternalAssetAddress(
                        address: addressString,
                        label: "\(asset.code) \(LocalizationConstants.rewardsAccount)",
                        onTxCompleted: onTxCompleted
                    )
                    .single
            }
            .map { $0 as ReceiveAddress }
    }

    public var requireSecondPassword: Single<Bool> {
        .just(false)
    }

    public var isFunded: Single<Bool> {
        balances.map { $0 != .absent }
    }

    public var pendingBalance: Single<MoneyValue> {
        balances
            .map(\.balance?.pending)
            .onNilJustReturn(.zero(currency: currencyType))
    }

    public var balance: Single<MoneyValue> {
        balances
            .map(\.balance?.available)
            .onNilJustReturn(.zero(currency: currencyType))
    }

    public var disabledReason: AnyPublisher<InterestAccountIneligibilityReason, Error> {
        interestEligibilityRepository
            .fetchInterestAccountEligibilityForCurrencyCode(currencyType)
            .map(\.ineligibilityReason)
            .eraseError()
            .eraseToAnyPublisher()
    }

    public var actionableBalance: Single<MoneyValue> {
        // `withdrawable` is the accounts total balance
        // minus the locked funds amount. Only these funds are
        // available for withdraws (which is all you can do with
        // your interest account funds)
        balances
            .map(\.balance)
            .map(\.?.withdrawable)
            .onNilJustReturn(.zero(currency: currencyType))
    }

    public var activity: Single<[ActivityItemEvent]> {
        activityPublisher
            .asSingle()
    }

    private var activityPublisher: AnyPublisher<[ActivityItemEvent], Never> {
        interestActivityEventRepository
            .fetchInterestActivityItemEventsForCryptoCurrency(asset)
            .map { events in
                events.map(ActivityItemEvent.interest)
            }
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }

    private var isInterestWithdrawAndDepositEnabled: AnyPublisher<Bool, Never> {
        featureFlagsService
            .isEnabled(
                .remote(.interestWithdrawAndDeposit)
            )
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }

    private let featureFlagsService: FeatureFlagsServiceAPI
    private let cryptoReceiveAddressFactory: ExternalAssetAddressFactory
    private let errorRecorder: ErrorRecording
    private let priceService: PriceServiceAPI
    private let interestEligibilityRepository: InterestAccountEligibilityRepositoryAPI
    private let receiveAddressRepository: InterestAccountReceiveAddressRepositoryAPI
    private let interestActivityEventRepository: InterestActivityItemEventRepositoryAPI
    private let balanceService: InterestAccountOverviewAPI
    private var balances: Single<CustodialAccountBalanceState> {
        balanceService.balance(for: asset)
    }

    public init(
        asset: CryptoCurrency,
        receiveAddressRepository: InterestAccountReceiveAddressRepositoryAPI = resolve(),
        priceService: PriceServiceAPI = resolve(),
        errorRecorder: ErrorRecording = resolve(),
        balanceService: InterestAccountOverviewAPI = resolve(),
        exchangeProviding: ExchangeProviding = resolve(),
        interestEligibilityRepository: InterestAccountEligibilityRepositoryAPI = resolve(),
        featureFlagService: FeatureFlagsServiceAPI = resolve(),
        interestActivityEventRepository: InterestActivityItemEventRepositoryAPI = resolve(),
        cryptoReceiveAddressFactory: ExternalAssetAddressFactory
    ) {
        label = asset.defaultInterestWalletName
        self.interestActivityEventRepository = interestActivityEventRepository
        self.cryptoReceiveAddressFactory = cryptoReceiveAddressFactory
        self.receiveAddressRepository = receiveAddressRepository
        self.asset = asset
        self.errorRecorder = errorRecorder
        self.balanceService = balanceService
        self.priceService = priceService
        self.interestEligibilityRepository = interestEligibilityRepository
        featureFlagsService = featureFlagService
    }

    public func can(perform action: AssetAction) -> AnyPublisher<Bool, Error> {
        switch action {
        case .interestWithdraw:
            return canPerformInterestWithdraw()
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .viewActivity:
            return activityPublisher
                .map { !$0.isEmpty }
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .buy,
             .deposit,
             .interestTransfer,
             .receive,
             .sell,
             .send,
             .sign,
             .swap,
             .withdraw:
            return .just(false)
        }
    }

    public func balancePair(
        fiatCurrency: FiatCurrency,
        at time: PriceTime
    ) -> AnyPublisher<MoneyValuePair, Error> {
        priceService
            .price(of: asset, in: fiatCurrency, at: time)
            .eraseError()
            .zip(balancePublisher)
            .tryMap { fiatPrice, balance in
                MoneyValuePair(base: balance, exchangeRate: fiatPrice.moneyValue)
            }
            .eraseToAnyPublisher()
    }

    private func canPerformInterestWithdraw() -> AnyPublisher<Bool, Never> {
        isInterestWithdrawAndDepositEnabled.setFailureType(to: Error.self)
            .zip(actionableBalance.map(\.isPositive).asPublisher())
            .map { enabled, positiveBalance in
                enabled && positiveBalance
            }
            .flatMap { [disabledReason] isAvailable -> AnyPublisher<Bool, Error> in
                guard isAvailable else {
                    return .just(false)
                }
                return disabledReason.map(\.isEligible)
                    .eraseToAnyPublisher()
            }
            .mapError { [label, asset] error -> CryptoInterestAccountError in
                .loadingFailed(
                    asset: asset.code,
                    label: label,
                    action: .interestWithdraw,
                    error: String(describing: error)
                )
            }
            .recordErrors(on: errorRecorder)
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }

    public func invalidateAccountBalance() {
        balanceService
            .invalidateInterestAccountBalances()
    }
}