// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BitcoinChainKit
import Combine
import DIKit
import Localization
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit
import WalletPayloadKit

final class BitcoinCashCryptoAccount: BitcoinChainCryptoAccount {

    let coinType: BitcoinChainCoin = .bitcoinCash

    private(set) lazy var identifier: AnyHashable = "BitcoinCashCryptoAccount.\(xPub.address).\(xPub.derivationType)"
    let label: String
    let asset: CryptoCurrency = .bitcoinCash
    let isDefault: Bool
    let hdAccountIndex: Int

    func createTransactionEngine() -> Any {
        BitcoinOnChainTransactionEngineFactory<BitcoinCashToken>()
    }

    var pendingBalance: AnyPublisher<MoneyValue, Error> {
        .just(.zero(currency: .bitcoinCash))
    }

    var balance: AnyPublisher<MoneyValue, Error> {
        balanceService
            .balance(for: xPub)
            .map(\.moneyValue)
            .eraseToAnyPublisher()
    }

    var actionableBalance: AnyPublisher<MoneyValue, Error> {
        balance
    }

    var receiveAddress: AnyPublisher<ReceiveAddress, Error> {
        receiveAddressProvider
            .receiveAddressProvider(UInt32(hdAccountIndex))
            .map { $0.replacingOccurrences(of: "bitcoincash:", with: "") }
            .eraseError()
            .map { [label, onTxCompleted] address -> ReceiveAddress in
                BitcoinChainReceiveAddress<BitcoinCashToken>(
                    address: address,
                    label: label,
                    onTxCompleted: onTxCompleted
                )
            }
            .eraseToAnyPublisher()
    }

    var firstReceiveAddress: AnyPublisher<ReceiveAddress, Error> {
        receiveAddressProvider
            .firstReceiveAddressProvider(UInt32(hdAccountIndex))
            .map { $0.replacingOccurrences(of: "bitcoincash:", with: "") }
            .eraseError()
            .map { [label, onTxCompleted] address -> ReceiveAddress in
                BitcoinChainReceiveAddress<BitcoinCashToken>(
                    address: address,
                    label: label,
                    onTxCompleted: onTxCompleted
                )
            }
            .eraseToAnyPublisher()
    }

    var activity: AnyPublisher<[ActivityItemEvent], Error> {
        nonCustodialActivity.zip(swapActivity)
            .map { nonCustodialActivity, swapActivity in
                Self.reconcile(swapEvents: swapActivity, noncustodial: nonCustodialActivity)
            }
            .eraseError()
            .eraseToAnyPublisher()
    }

    private var isInterestTransferAvailable: AnyPublisher<Bool, Never> {
        guard asset.supports(product: .interestBalance) else {
            return .just(false)
        }
        return isInterestWithdrawAndDepositEnabled
            .zip(canPerformInterestTransfer)
            .map { isEnabled, canPerform in
                isEnabled && canPerform
            }
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }

    private var nonCustodialActivity: AnyPublisher<[TransactionalActivityItemEvent], Never> {
        transactionsService
            .transactions(publicKeys: [xPub])
            .map { response in
                response
                    .map(\.activityItemEvent)
            }
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }

    private var swapActivity: AnyPublisher<[SwapActivityItemEvent], Never> {
        swapTransactionsService
            .fetchActivity(cryptoCurrency: asset, directions: custodialDirections)
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }

    private var isInterestWithdrawAndDepositEnabled: AnyPublisher<Bool, Never> {
        featureFlagsService
            .isEnabled(.interestWithdrawAndDeposit)
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }

    let xPub: XPub
    private let featureFlagsService: FeatureFlagsServiceAPI
    private let balanceService: BalanceServiceAPI
    private let priceService: PriceServiceAPI
    private let transactionsService: BitcoinCashHistoricalTransactionServiceAPI
    private let swapTransactionsService: SwapActivityServiceAPI
    private let receiveAddressProvider: BitcoinChainReceiveAddressProviderAPI

    init(
        xPub: XPub,
        label: String?,
        isDefault: Bool,
        hdAccountIndex: Int,
        priceService: PriceServiceAPI = resolve(),
        transactionsService: BitcoinCashHistoricalTransactionServiceAPI = resolve(),
        swapTransactionsService: SwapActivityServiceAPI = resolve(),
        balanceService: BalanceServiceAPI = resolve(tag: BitcoinChainCoin.bitcoinCash),
        featureFlagsService: FeatureFlagsServiceAPI = resolve(),
        receiveAddressProvider: BitcoinChainReceiveAddressProviderAPI = resolve(
            tag: BitcoinChainKit.BitcoinChainCoin.bitcoinCash
        )
    ) {
        self.xPub = xPub
        self.label = label ?? CryptoCurrency.bitcoinCash.defaultWalletName
        self.isDefault = isDefault
        self.hdAccountIndex = hdAccountIndex
        self.priceService = priceService
        self.balanceService = balanceService
        self.transactionsService = transactionsService
        self.swapTransactionsService = swapTransactionsService
        self.featureFlagsService = featureFlagsService
        self.receiveAddressProvider = receiveAddressProvider
    }

    func can(perform action: AssetAction) -> AnyPublisher<Bool, Error> {
        switch action {
        case .receive,
             .send,
             .buy,
             .linkToDebitCard,
             .viewActivity:
            return .just(true)
        case .deposit,
             .sign,
             .withdraw,
             .interestWithdraw:
            return .just(false)
        case .stakingDeposit:
            guard asset.supports(product: .stakingBalance) else { return .just(false) }
            return isFunded
        case .interestTransfer:
            return isInterestTransferAvailable
                .flatMap { [isFunded] isEnabled in
                    isEnabled ? isFunded : .just(false)
                }
                .eraseToAnyPublisher()
        case .sell, .swap:
            return hasPositiveDisplayableBalance
        }
    }

    func balancePair(
        fiatCurrency: FiatCurrency,
        at time: PriceTime
    ) -> AnyPublisher<MoneyValuePair, Error> {
        balancePair(
            priceService: priceService,
            fiatCurrency: fiatCurrency,
            at: time
        )
    }

    func mainBalanceToDisplayPair(
        fiatCurrency: FiatCurrency,
        at time: PriceTime
    ) -> AnyPublisher<MoneyValuePair, Error> {
        mainBalanceToDisplayPair(
            priceService: priceService,
            fiatCurrency: fiatCurrency,
            at: time
        )
    }

    func updateLabel(_ newLabel: String) -> Completable {
        // TODO: @native-wallet allow BCH accounts to be renamed.
        .empty()
    }

    func invalidateAccountBalance() {
        balanceService
            .invalidateBalanceForWallet(xPub)
    }
}
