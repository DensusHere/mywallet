// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

final class NonCustodialSellTransactionEngine: SellTransactionEngine {

    let canTransactFiat: Bool = false
    let receiveAddressFactory: ExternalAssetAddressServiceAPI
    let walletCurrencyService: FiatCurrencyServiceAPI
    let currencyConversionService: CurrencyConversionServiceAPI
    let onChainEngine: OnChainTransactionEngine
    let orderCreationRepository: OrderCreationRepositoryAPI
    let orderDirection: OrderDirection = .fromUserKey
    let orderQuoteRepository: OrderQuoteRepositoryAPI
    let orderUpdateRepository: OrderUpdateRepositoryAPI
    let quotesEngine: QuotesEngine
    let hotWalletAddressService: HotWalletAddressServiceAPI
    let requireSecondPassword: Bool
    let transactionLimitsService: TransactionLimitsServiceAPI

    var askForRefreshConfirmation: AskForRefreshConfirmation!
    var sourceAccount: BlockchainAccount!
    var transactionTarget: TransactionTarget!

    init(
        quotesEngine: QuotesEngine,
        requireSecondPassword: Bool,
        onChainEngine: OnChainTransactionEngine,
        orderQuoteRepository: OrderQuoteRepositoryAPI = resolve(),
        orderCreationRepository: OrderCreationRepositoryAPI = resolve(),
        orderUpdateRepository: OrderUpdateRepositoryAPI = resolve(),
        transactionLimitsService: TransactionLimitsServiceAPI = resolve(),
        walletCurrencyService: FiatCurrencyServiceAPI = resolve(),
        currencyConversionService: CurrencyConversionServiceAPI = resolve(),
        receiveAddressFactory: ExternalAssetAddressServiceAPI = resolve(),
        hotWalletAddressService: HotWalletAddressServiceAPI = resolve()
    ) {
        self.quotesEngine = quotesEngine
        self.requireSecondPassword = requireSecondPassword
        self.orderQuoteRepository = orderQuoteRepository
        self.orderCreationRepository = orderCreationRepository
        self.orderUpdateRepository = orderUpdateRepository
        self.transactionLimitsService = transactionLimitsService
        self.walletCurrencyService = walletCurrencyService
        self.currencyConversionService = currencyConversionService
        self.onChainEngine = onChainEngine
        self.receiveAddressFactory = receiveAddressFactory
        self.hotWalletAddressService = hotWalletAddressService
    }

    func assertInputsValid() {
        precondition(sourceAccount is NonCustodialAccount)
        precondition(transactionTarget is FiatAccount)
    }

    private func startOnChainEngine(pricedQuote: PricedQuote) -> Single<Void> {
        let value = receiveAddressFactory.makeExternalAssetAddress(
            asset: sourceAsset,
            address: pricedQuote.sampleDepositAddress,
            label: pricedQuote.sampleDepositAddress,
            onTxCompleted: { _ in .empty() }
        )
        switch value {
        case .failure(let error):
            return .error(error)
        case .success(let receiveAddress):
            return createTransactionTarget(depositAddress: receiveAddress.address)
                .flatMap { [onChainEngine, sourceAccount] transactionTarget in
                    onChainEngine.start(
                        sourceAccount: sourceAccount!,
                        transactionTarget: transactionTarget,
                        askForRefreshConfirmation: { _ in .empty() }
                    )
                    return .just(())
                }
        }
    }

    private func defaultFeeLevel(pendingTransaction: PendingTransaction) -> FeeLevel {
        if pendingTransaction.feeSelection.availableLevels.contains(.priority) {
            return .priority
        }
        return pendingTransaction.feeSelection.selectedLevel
    }

    func initializeTransaction() -> Single<PendingTransaction> {
        quotesEngine
            .startPollingRate(
                direction: orderDirection,
                pair: .init(
                    sourceCurrencyType: sourceAsset,
                    destinationCurrencyType: target.currencyType
                )
            )
        return quotesEngine
            .quotePublisher
            .asSingle()
            .flatMap { [weak self] pricedQuote -> Single<PendingTransaction> in
                guard let self = self else { return .error(ToolKitError.nullReference(Self.self)) }
                return self.startOnChainEngine(pricedQuote: pricedQuote)
                    .flatMap { [weak self] _ -> Single<(FiatCurrency, PendingTransaction)> in
                        guard let self = self else { return .error(ToolKitError.nullReference(Self.self)) }
                        return Single.zip(
                            self.walletCurrencyService.displayCurrency.asSingle(),
                            self.onChainEngine.initializeTransaction()
                        )
                    }
                    .flatMap { [weak self] fiatCurrency, pendingTransaction -> Single<PendingTransaction> in
                        guard let self = self else { return .error(ToolKitError.nullReference(Self.self)) }
                        let fallback = PendingTransaction(
                            amount: .zero(currency: self.sourceAsset),
                            available: .zero(currency: self.targetAsset),
                            feeAmount: .zero(currency: self.targetAsset),
                            feeForFullAvailable: .zero(currency: self.sourceAsset),
                            feeSelection: .empty(asset: self.sourceAsset),
                            selectedFiatCurrency: fiatCurrency
                        )
                        return self.updateLimits(
                            pendingTransaction: pendingTransaction,
                            pricedQuote: pricedQuote
                        )
                        .map { [weak self] pendingTx -> PendingTransaction in
                            guard let self = self else { throw ToolKitError.nullReference(Self.self) }
                            return pendingTx.update(
                                selectedFeeLevel: self.defaultFeeLevel(pendingTransaction: pendingTx)
                            )
                        }
                        .handlePendingOrdersError(initialValue: fallback)
                    }
            }
    }

    func execute(pendingTransaction: PendingTransaction, secondPassword: String) -> Single<TransactionResult> {
        createOrder(pendingTransaction: pendingTransaction)
            .flatMap { [weak self] sellOrder -> Single<TransactionResult> in
                guard let self = self else { return .error(ToolKitError.nullReference(Self.self)) }
                guard let depositAddress = sellOrder.depositAddress else {
                    throw PlatformKitError.illegalStateException(message: "Missing deposit address")
                }
                return self.receiveAddressFactory
                    .makeExternalAssetAddress(
                        asset: self.sourceAsset,
                        address: depositAddress,
                        label: depositAddress,
                        onTxCompleted: { _ in .empty() }
                    )
                    .single
                    .flatMap { [weak self] transactionTarget -> Single<PendingTransaction> in
                        guard let self = self else { return .error(ToolKitError.nullReference(Self.self)) }
                        return self.onChainEngine
                            .restart(transactionTarget: transactionTarget, pendingTransaction: pendingTransaction)
                    }
                    .flatMap { [weak self] pendingTransaction -> Single<TransactionResult> in
                        guard let self = self else { return .error(ToolKitError.nullReference(Self.self)) }
                        return self.onChainEngine
                            .execute(pendingTransaction: pendingTransaction, secondPassword: secondPassword)
                            .catch { [weak self] error -> Single<TransactionResult> in
                                guard let self = self else { return .error(ToolKitError.nullReference(Self.self)) }
                                return self.orderUpdateRepository
                                    .updateOrder(identifier: sellOrder.identifier, success: false)
                                    .asCompletable()
                                    .catch { _ in .empty() }
                                    .andThen(.error(error))
                            }
                            .flatMap { [weak self] result -> Single<TransactionResult> in
                                guard let self = self else { return .error(ToolKitError.nullReference(Self.self)) }
                                return self.orderUpdateRepository
                                    .updateOrder(identifier: sellOrder.identifier, success: true)
                                    .asCompletable()
                                    .catch { _ in .empty() }
                                    .andThen(.just(result))
                            }
                    }
            }
    }

    /**
     Creates TransactionTarget for executing the on chain transaction.

     - Returns: Single that emits a TransactionTarget. If there is no hot wallet address for 'swap' associated with the current currency,
     then the emitted value will be the order deposit address. Else, if there is a hot wallet address, it will emit a HotWalletTransactionTarget.

     When sending a transaction to one of Blockchain's custodial products, we check if a hot wallet address for that product
     is available. If that is not available, reference address is null and the transaction happens as it normally would. If it is available,
     we will send the fund directly to the hot wallet address, and pass along the original address (real address) as the
     reference address, that will be added to the transaction data field or as a the third parameter of the overloaded transfer method.
     You can check how this works and the reasons for its implementation here:
     https://www.notion.so/blockchaincom/Up-to-75-cheaper-EVM-wallet-private-key-to-custody-transfers-9675695a02ec49b893af1095ead6cc07
     */
    private func createTransactionTarget(
        depositAddress: String
    ) -> Single<TransactionTarget> {
        let depositAddress = receiveAddressFactory.makeExternalAssetAddress(
            asset: sourceAsset,
            address: depositAddress,
            label: depositAddress,
            onTxCompleted: { _ in .empty() }
        )
        return Single
            .zip(
                depositAddress.single,
                hotWalletReceiveAddress
            )
            .map { depositAddress, hotWalletAddress -> TransactionTarget in
                guard let hotWalletAddress = hotWalletAddress else {
                    return depositAddress
                }
                return HotWalletTransactionTarget(
                    realAddress: depositAddress,
                    hotWalletAddress: hotWalletAddress
                )
            }
    }

    /// Returns the Hot Wallet receive address for the current cryptocurrency.
    private var hotWalletReceiveAddress: Single<CryptoReceiveAddress?> {
        hotWalletAddressService
            .hotWalletAddress(for: sourceAsset, product: .trading)
            .asSingle()
            .flatMap { [sourceAsset, receiveAddressFactory] hotWalletAddress -> Single<CryptoReceiveAddress?> in
                guard let hotWalletAddress = hotWalletAddress else {
                    return .just(nil)
                }
                return receiveAddressFactory.makeExternalAssetAddress(
                    asset: sourceAsset,
                    address: hotWalletAddress,
                    label: hotWalletAddress,
                    onTxCompleted: { _ in .empty() }
                )
                .single
                .optional()
            }
            .catchAndReturn(nil)
    }

    func doUpdateFeeLevel(
        pendingTransaction: PendingTransaction,
        level: FeeLevel,
        customFeeAmount: MoneyValue
    ) -> Single<PendingTransaction> {
        onChainEngine.doUpdateFeeLevel(
            pendingTransaction: pendingTransaction,
            level: level,
            customFeeAmount: customFeeAmount
        )
    }

    func update(amount: MoneyValue, pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        validateUpdateAmount(amount)
            .flatMap { [weak self] amount -> Single<PendingTransaction> in
                guard let self = self else { return .error(ToolKitError.nullReference(Self.self)) }
                return self.onChainEngine
                    .update(amount: amount, pendingTransaction: pendingTransaction)
                    .do(onSuccess: { [weak self] pendingTransaction in
                        guard let self = self else { throw ToolKitError.nullReference(Self.self) }
                        self.quotesEngine.update(amount: pendingTransaction.amount.amount)
                    })
                    .map { [weak self] pendingTransaction -> PendingTransaction in
                        guard let self = self else { throw ToolKitError.nullReference(Self.self) }
                        return self.clearConfirmations(pendingTransaction: pendingTransaction)
                    }
            }
    }

    func validateAmount(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        onChainEngine
            .validateAmount(pendingTransaction: pendingTransaction)
            .flatMap { [weak self] pendingTransaction -> Single<PendingTransaction> in
                guard let self = self else { return .error(ToolKitError.nullReference(Self.self)) }
                switch pendingTransaction.validationState {
                case .canExecute:
                    return self.defaultValidateAmount(pendingTransaction: pendingTransaction)
                default:
                    return .just(pendingTransaction)
                }
            }
            .updateTxValiditySingle(pendingTransaction: pendingTransaction)
    }

    func doValidateAll(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        onChainEngine
            .doValidateAll(pendingTransaction: pendingTransaction)
            .flatMap { [weak self] pendingTransaction -> Single<PendingTransaction> in
                guard let self = self else { return .error(ToolKitError.nullReference(Self.self)) }
                switch pendingTransaction.validationState {
                case .canExecute:
                    return self.defaultDoValidateAll(pendingTransaction: pendingTransaction)
                default:
                    return .just(pendingTransaction)
                }
            }
            .updateTxValiditySingle(pendingTransaction: pendingTransaction)
    }

    func doBuildConfirmations(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        quotesEngine
            .quotePublisher
            .asSingle()
            .map { [targetAsset, sourceAccount, target] pricedQuote -> (PendingTransaction, PricedQuote) in
                let resultValue = FiatValue(amount: pricedQuote.price, currency: targetAsset).moneyValue
                let baseValue = MoneyValue.one(currency: pendingTransaction.amount.currency)
                let sellDestinationValue: MoneyValue = pendingTransaction.amount.convert(using: resultValue)
                let sellFiatFeeValue: MoneyValue = pendingTransaction.feeAmount.convert(using: resultValue)

                var confirmations = [TransactionConfirmation]()

                if let pendingTransactionAmount = pendingTransaction.amount.cryptoValue {
                    confirmations.append(
                        TransactionConfirmations.SellSourceValue(
                            cryptoValue: pendingTransactionAmount
                        )
                    )
                }
                if let sellDestinationFiatValue = sellDestinationValue.fiatValue {
                    confirmations.append(
                        TransactionConfirmations.SellDestinationValue(
                            fiatValue: sellDestinationFiatValue
                        )
                    )
                }
                confirmations.append(
                    TransactionConfirmations.SellExchangeRateValue(
                        baseValue: baseValue,
                        resultValue: resultValue
                    )
                )
                if let sourceAccountLabel = sourceAccount?.label {
                    confirmations.append(TransactionConfirmations.Source(value: sourceAccountLabel))
                }
                if !pricedQuote.staticFee.isZero {
                    confirmations.append(TransactionConfirmations.FiatTransactionFee(fee: pricedQuote.staticFee))
                }
                confirmations += [
                    TransactionConfirmations.Destination(value: target.label),
                    TransactionConfirmations.NetworkFee(
                        primaryCurrencyFee: pendingTransaction.feeAmount,
                        secondaryCurrencyFee: sellFiatFeeValue,
                        feeType: .withdrawalFee
                    )
                ]
                if let sellTotalFiatValue = (try? sellDestinationValue + sellFiatFeeValue),
                   let sellTotalCryptoValue = (try? pendingTransaction.amount + pendingTransaction.feeAmount)
                {
                    confirmations.append(
                        TransactionConfirmations.TotalCost(
                            primaryCurrencyFee: sellTotalCryptoValue,
                            secondaryCurrencyFee: sellTotalFiatValue
                        )
                    )
                }
                let updatedTransaction = pendingTransaction.update(confirmations: confirmations)
                return (updatedTransaction, pricedQuote)
            }
            .flatMap { [weak self] pendingTransaction, pricedQuote in
                guard let self = self else { return .error(ToolKitError.nullReference(Self.self)) }
                return self.updateLimits(pendingTransaction: pendingTransaction, pricedQuote: pricedQuote)
            }
    }
}
