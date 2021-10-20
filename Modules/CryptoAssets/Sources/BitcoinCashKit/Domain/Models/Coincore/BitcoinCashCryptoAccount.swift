// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BitcoinChainKit
import Combine
import DIKit
import Localization
import PlatformKit
import RxSwift
import ToolKit

final class BitcoinCashCryptoAccount: CryptoNonCustodialAccount {

    private(set) lazy var identifier: AnyHashable = "BitcoinCashCryptoAccount.\(xPub.address).\(xPub.derivationType)"
    let label: String
    let asset: CryptoCurrency = .coin(.bitcoinCash)
    let isDefault: Bool

    func createTransactionEngine() -> Any {
        BitcoinOnChainTransactionEngineFactory<BitcoinCashToken>()
    }

    var pendingBalance: Single<MoneyValue> {
        .just(.zero(currency: .coin(.bitcoinCash)))
    }

    var balance: Single<MoneyValue> {
        balanceService
            .balance(for: xPub)
            .asSingle()
            .moneyValue
    }

    var actionableBalance: Single<MoneyValue> {
        balance
    }

    var actions: Single<AvailableActions> {
        Single.zip(
            isFunded,
            canPerformInterestTransfer(),
            featureFlagsService
                .isEnabled(.remote(.sellUsingTransactionFlowEnabled)).asSingle()
        )
        .map { isFunded, isInterestTransferEnabled, isSellEnabled -> AvailableActions in
            var base: AvailableActions = [.viewActivity, .receive, .send, .buy]
            if isFunded {
                base.insert(.swap)
                if isSellEnabled {
                    base.insert(.sell)
                }
                if isInterestTransferEnabled {
                    base.insert(.interestTransfer)
                }
            }
            return base
        }
    }

    var receiveAddress: Single<ReceiveAddress> {
        let receiveAddress: Single<String> = bridge.receiveAddress(forXPub: xPub.address)
        let account: Single<BitcoinCashWalletAccount> = bridge
            .wallets
            .map { [xPub] wallets in
                wallets.filter { $0.publicKey == xPub }
            }
            .map { accounts -> BitcoinCashWalletAccount in
                guard let account = accounts.first else {
                    throw PlatformKitError.illegalStateException(message: "Expected a BitcoinCashWalletAccount")
                }
                return account
            }

        return Single.zip(receiveAddress, account)
            .map { [label, onTxCompleted] address, account -> ReceiveAddress in
                BitcoinChainReceiveAddress<BitcoinCashToken>(
                    address: address,
                    label: label,
                    onTxCompleted: onTxCompleted,
                    index: Int32(account.index)
                )
            }
    }

    var activity: Single<[ActivityItemEvent]> {
        Single.zip(nonCustodialActivity, swapActivity)
            .map { nonCustodialActivity, swapActivity in
                Self.reconcile(swapEvents: swapActivity, noncustodial: nonCustodialActivity)
            }
    }

    private var nonCustodialActivity: Single<[TransactionalActivityItemEvent]> {
        transactionsService
            .transactions(publicKeys: [xPub])
            .map { response in
                response
                    .map(\.activityItemEvent)
            }
            .catchErrorJustReturn([])
    }

    private var swapActivity: Single<[SwapActivityItemEvent]> {
        swapTransactionsService
            .fetchActivity(cryptoCurrency: asset, directions: custodialDirections)
            .catchErrorJustReturn([])
    }

    private let xPub: XPub
    private let hdAccountIndex: Int
    private let balanceService: BalanceServiceAPI
    private let priceService: PriceServiceAPI
    private let bridge: BitcoinCashWalletBridgeAPI
    private let transactionsService: BitcoinCashHistoricalTransactionServiceAPI
    private let swapTransactionsService: SwapActivityServiceAPI
    private let featureFlagsService: FeatureFlagsServiceAPI

    init(
        xPub: XPub,
        label: String?,
        isDefault: Bool,
        hdAccountIndex: Int,
        priceService: PriceServiceAPI = resolve(),
        transactionsService: BitcoinCashHistoricalTransactionServiceAPI = resolve(),
        swapTransactionsService: SwapActivityServiceAPI = resolve(),
        balanceService: BalanceServiceAPI = resolve(tag: BitcoinChainCoin.bitcoinCash),
        bridge: BitcoinCashWalletBridgeAPI = resolve(),
        featureFlagsService: FeatureFlagsServiceAPI = resolve()
    ) {
        self.xPub = xPub
        self.label = label ?? CryptoCurrency.coin(.bitcoinCash).defaultWalletName
        self.isDefault = isDefault
        self.hdAccountIndex = hdAccountIndex
        self.priceService = priceService
        self.balanceService = balanceService
        self.transactionsService = transactionsService
        self.swapTransactionsService = swapTransactionsService
        self.bridge = bridge
        self.featureFlagsService = featureFlagsService
    }

    func can(perform action: AssetAction) -> Single<Bool> {
        switch action {
        case .receive,
             .send,
             .buy,
             .viewActivity:
            return .just(true)
        case .interestTransfer:
            return canPerformInterestTransfer()
                .flatMap { [isFunded] isEnabled in
                    isEnabled ? isFunded : .just(false)
                }
        case .deposit,
             .withdraw,
             .interestWithdraw:
            return .just(false)
        case .sell:
            return featureFlagsService
                .isEnabled(.remote(.sellUsingTransactionFlowEnabled))
                .asSingle()
                .flatMap(weak: self) { _, isEnabled in
                    isEnabled
                        ? self.isFunded
                        : .just(false)
                }
        case .swap:
            return isFunded
        }
    }

    func balancePair(fiatCurrency: FiatCurrency, at time: PriceTime) -> AnyPublisher<MoneyValuePair, Error> {
        priceService
            .price(of: asset, in: fiatCurrency, at: time)
            .eraseError()
            .zip(balance.asPublisher())
            .tryMap { fiatPrice, balance in
                MoneyValuePair(base: balance, exchangeRate: fiatPrice.moneyValue)
            }
            .eraseToAnyPublisher()
    }

    func updateLabel(_ newLabel: String) -> Completable {
        bridge.update(accountIndex: hdAccountIndex, label: newLabel)
    }
}
