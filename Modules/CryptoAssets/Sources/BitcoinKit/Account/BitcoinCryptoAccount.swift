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

final class BitcoinCryptoAccount: BitcoinChainCryptoAccount {

    let coinType: BitcoinChainCoin = .bitcoin

    private(set) lazy var identifier: AnyHashable = "BitcoinCryptoAccount.\(xPub.address).\(xPub.derivationType)"
    let label: String
    let asset: CryptoCurrency = .bitcoin
    let isDefault: Bool
    let hdAccountIndex: Int

    func createTransactionEngine() -> Any {
        BitcoinOnChainTransactionEngineFactory<BitcoinToken>()
    }

    var pendingBalance: AnyPublisher<MoneyValue, Error> {
        .just(.zero(currency: .bitcoin))
    }

    var actionableBalance: AnyPublisher<MoneyValue, Error> {
        balance
    }

    var balance: AnyPublisher<MoneyValue, Error> {
        balanceService
            .balances(for: walletAccount.publicKeys.xpubs)
            .map(\.moneyValue)
            .eraseToAnyPublisher()
    }

    var receiveAddress: AnyPublisher<ReceiveAddress, Error> {
        // TODO: use native receive address fetching
        bridge.receiveAddress(forXPub: xPub.address)
            .map { [label, onTxCompleted] address -> ReceiveAddress in
                BitcoinChainReceiveAddress<BitcoinToken>(
                    address: address,
                    label: label,
                    onTxCompleted: onTxCompleted
                )
            }
            .asPublisher()
            .eraseToAnyPublisher()
    }

    var firstReceiveAddress: AnyPublisher<ReceiveAddress, Error> {
        bridge.firstReceiveAddress(forXPub: xPub.address)
            .map { [label, onTxCompleted] address -> ReceiveAddress in
                BitcoinChainReceiveAddress<BitcoinToken>(
                    address: address,
                    label: label,
                    onTxCompleted: onTxCompleted
                )
            }
            .asPublisher()
            .eraseToAnyPublisher()
    }

    var activity: Single<[ActivityItemEvent]> {
        Single.zip(nonCustodialActivity, swapActivity.asSingle())
            .map { nonCustodialActivity, swapActivity in
                Self.reconcile(swapEvents: swapActivity, noncustodial: nonCustodialActivity)
            }
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

    private var isInterestWithdrawAndDepositEnabled: AnyPublisher<Bool, Never> {
        featureFlagsService
            .isEnabled(.interestWithdrawAndDeposit)
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }

    private var nonCustodialActivity: Single<[TransactionalActivityItemEvent]> {
        transactionsService
            .transactions(publicKeys: walletAccount.publicKeys.xpubs)
            .map { response in
                response
                    .map(\.activityItemEvent)
            }
            .catchAndReturn([])
    }

    private var swapActivity: AnyPublisher<[SwapActivityItemEvent], Never> {
        swapTransactionsService
            .fetchActivity(cryptoCurrency: asset, directions: custodialDirections)
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }

    private let featureFlagsService: FeatureFlagsServiceAPI
    let xPub: XPub // TODO: Change this to `XPubs`
    private let balanceService: BalanceServiceAPI
    private let bridge: BitcoinWalletBridgeAPI
    private let priceService: PriceServiceAPI
    private let walletAccount: BitcoinWalletAccount
    private let transactionsService: BitcoinHistoricalTransactionServiceAPI
    private let swapTransactionsService: SwapActivityServiceAPI

    init(
        walletAccount: BitcoinWalletAccount,
        isDefault: Bool,
        balanceService: BalanceServiceAPI = resolve(tag: BitcoinChainKit.BitcoinChainCoin.bitcoin),
        transactionsService: BitcoinHistoricalTransactionServiceAPI = resolve(),
        swapTransactionsService: SwapActivityServiceAPI = resolve(),
        priceService: PriceServiceAPI = resolve(),
        bridge: BitcoinWalletBridgeAPI = resolve(),
        featureFlagsService: FeatureFlagsServiceAPI = resolve()
    ) {
        xPub = walletAccount.publicKeys.default
        hdAccountIndex = walletAccount.index
        label = walletAccount.label ?? CryptoCurrency.bitcoin.defaultWalletName
        self.isDefault = isDefault
        self.balanceService = balanceService
        self.priceService = priceService
        self.transactionsService = transactionsService
        self.swapTransactionsService = swapTransactionsService
        self.bridge = bridge
        self.walletAccount = walletAccount
        self.featureFlagsService = featureFlagsService
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

    func updateLabel(_ newLabel: String) -> Completable {
        bridge.update(accountIndex: hdAccountIndex, label: newLabel)
    }

    func invalidateAccountBalance() {
        balanceService
            .invalidateBalanceForWallet(xPub)
    }
}
