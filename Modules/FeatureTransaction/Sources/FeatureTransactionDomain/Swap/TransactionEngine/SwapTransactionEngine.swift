// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import Combine
import DIKit
import MoneyKit
import NabuNetworkError
import PlatformKit
import RxSwift
import ToolKit

protocol SwapTransactionEngine: TransactionEngine {

    var orderDirection: OrderDirection { get }
    var quotesEngine: QuotesEngine { get }
    var orderCreationRepository: OrderCreationRepositoryAPI { get }
    var transactionLimitsService: TransactionLimitsServiceAPI { get }
    var quote: Observable<PricedQuote> { get }
}

extension PendingTransaction {

    fileprivate var quoteSubscription: Disposable? {
        engineState[.quoteSubscription] as? Disposable
    }
}

extension SwapTransactionEngine {

    var target: CryptoAccount { transactionTarget as! CryptoAccount }
    var targetAsset: CryptoCurrency { target.asset }
    var sourceAsset: CryptoCurrency { sourceCryptoCurrency }

    var pair: OrderPair {
        OrderPair(
            sourceCurrencyType: sourceAsset.currencyType,
            destinationCurrencyType: target.asset.currencyType
        )
    }

    // MARK: - TransactionEngine

    func validateUpdateAmount(_ amount: MoneyValue) -> Single<MoneyValue> {
        .just(amount)
    }

    var fiatExchangeRatePairs: Observable<TransactionMoneyValuePairs> {
        Single.zip(sourceExchangeRatePair, destinationExchangeRatePair)
            .map { tuple -> TransactionMoneyValuePairs in
                let (source, destination) = tuple
                return TransactionMoneyValuePairs(
                    source: source,
                    destination: destination
                )
            }
            .asObservable()
    }

    var transactionExchangeRatePair: Observable<MoneyValuePair> {
        quote
            .map(weak: self) { (self, pricedQuote) -> MoneyValue in
                MoneyValue(amount: pricedQuote.price, currency: self.target.currencyType)
            }
            .map(weak: self) { (self, rate) -> MoneyValuePair in
                MoneyValuePair(base: .one(currency: self.sourceAsset), exchangeRate: rate)
            }
    }

    private func disposeQuotesFetching(pendingTransaction: PendingTransaction) {
        pendingTransaction.quoteSubscription?.dispose()
        quotesEngine.stop()
    }

    func clearConfirmations(pendingTransaction oldValue: PendingTransaction) -> PendingTransaction {
        var pendingTransaction = oldValue
        let quoteSubscription = pendingTransaction.quoteSubscription
        quoteSubscription?.dispose()
        pendingTransaction.engineState[.quoteSubscription] = nil
        return pendingTransaction.update(confirmations: [])
    }

    func stop(pendingTransaction: PendingTransaction) {
        disposeQuotesFetching(pendingTransaction: pendingTransaction)
    }

    func updateLimits(
        pendingTransaction: PendingTransaction,
        pricedQuote: PricedQuote
    ) -> Single<PendingTransaction> {
        let limitsPublisher = transactionLimitsService.fetchLimits(
            source: LimitsAccount(
                currency: sourceAsset.currencyType,
                accountType: orderDirection.isFromCustodial ? .custodial : .nonCustodial
            ),
            destination: LimitsAccount(
                currency: targetAsset.currencyType,
                accountType: orderDirection.isToCustodial ? .custodial : .nonCustodial
            ),
            product: .swap(orderDirection)
        )
        return limitsPublisher
            .asSingle()
            .map { transactionLimits -> PendingTransaction in
                var pendingTransaction = pendingTransaction
                pendingTransaction.limits = try transactionLimits.update(with: pricedQuote)
                return pendingTransaction
            }
    }

    func doValidateAll(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        defaultDoValidateAll(pendingTransaction: pendingTransaction)
    }

    func defaultDoValidateAll(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        validateAmount(pendingTransaction: pendingTransaction)
    }

    func doBuildConfirmations(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        let quote = quote
            .take(1)
            .asSingle()
        let amountInSourceCurrency = currencyConversionService
            .convert(pendingTransaction.amount, to: sourceAsset.currencyType)
            .asSingle()
        let sourceAsset = sourceAsset, targetAsset = targetAsset
        return Single
            .zip(quote, amountInSourceCurrency)
            .map { [sourceAccount, target] pricedQuote, convertedAmount -> (PendingTransaction, PricedQuote) in
                let resultValue = CryptoValue(amount: pricedQuote.price, currency: targetAsset).moneyValue
                let swapDestinationValue: MoneyValue = convertedAmount.convert(using: resultValue)
                let confirmations: [TransactionConfirmation] = [
                    .swapSourceValue(.init(cryptoValue: convertedAmount.cryptoValue!)),
                    .swapDestinationValue(.init(cryptoValue: swapDestinationValue.cryptoValue!)),
                    .swapExchangeRate(.init(baseValue: .one(currency: sourceAsset), resultValue: resultValue)),
                    .source(.init(value: sourceAccount!.label)),
                    .destination(.init(value: target.label)),
                    .networkFee(.init(
                        primaryCurrencyFee: pricedQuote.networkFee,
                        feeType: .withdrawalFee
                    )),
                    .networkFee(.init(
                        primaryCurrencyFee: pendingTransaction.feeAmount,
                        feeType: .depositFee
                    ))
                ]

                let updatedTransaction = pendingTransaction.update(confirmations: confirmations)
                return (updatedTransaction, pricedQuote)
            }
            .flatMap(weak: self) { (self, tuple) in
                let (pendingTransaction, pricedQuote) = tuple
                return self.updateLimits(pendingTransaction: pendingTransaction, pricedQuote: pricedQuote)
            }
    }

    func startConfirmationsUpdate(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        startQuotesFetchingIfNotStarted(pendingTransaction: pendingTransaction)
    }

    private func startQuotesFetchingIfNotStarted(
        pendingTransaction oldValue: PendingTransaction
    ) -> Single<PendingTransaction> {
        guard oldValue.quoteSubscription == nil else {
            return .just(oldValue)
        }
        var pendingTransaction = oldValue
        pendingTransaction.engineState[.quoteSubscription] = startQuotesFetching()
        return .just(pendingTransaction)
    }

    private func startQuotesFetching() -> Disposable {
        quote
            .flatMap { [weak self] _ -> Completable in
                guard let self = self else { return .empty() }
                return self.askForRefreshConfirmation(true)
            }
            .subscribe()
    }

    func doRefreshConfirmations(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        doBuildConfirmations(pendingTransaction: pendingTransaction)
    }

    // MARK: - Exchange Rates

    func sourceToDestinationTradingCurrencyRate(
        pendingTransaction: PendingTransaction,
        tradingCurrency: FiatCurrency
    ) -> AnyPublisher<MoneyValue, PriceServiceError> {
        sourceExchangeRatePair.asPublisher()
            .map(\.quote)
            .mapError { _ in PriceServiceError.missingPrice }
            .eraseToAnyPublisher()
    }

    // MARK: - SwapTransactionEngine

    func createOrder(pendingTransaction: PendingTransaction) -> Single<SwapOrder> {
        let amountInSourceCurrency = currencyConversionService
            .convert(pendingTransaction.amount, to: sourceAsset.currencyType)

        return Single.zip(
            target.receiveAddress,
            sourceAccount.receiveAddress,
            amountInSourceCurrency.asSingle()
        )
        .flatMap { [weak self] destinationAddress, refundAddress, convertedAmount -> Single<SwapOrder> in
            guard let self = self else { return .never() }
            return self.quote
                .take(1)
                .asSingle()
                .flatMap { [weak self] quote -> Single<SwapOrder> in
                    guard let self = self else { return .never() }
                    let destination = self.orderDirection.requiresDestinationAddress ? destinationAddress.address : nil
                    let refund = self.orderDirection.requiresRefundAddress ? refundAddress.address : nil
                    return self.orderCreationRepository
                        .createOrder(
                            direction: self.orderDirection,
                            quoteIdentifier: quote.identifier,
                            volume: convertedAmount,
                            destinationAddress: destination,
                            refundAddress: refund
                        )
                        .asSingle()
                }
        }
        .do(onDispose: { [weak self] in
            self?.disposeQuotesFetching(pendingTransaction: pendingTransaction)
        })
    }

    // MARK: - Private Functions

    private var sourceExchangeRatePair: Single<MoneyValuePair> {
        transactionExchangeRatePair
            .take(1)
            .asSingle()
    }

    private var destinationExchangeRatePair: Single<MoneyValuePair> {
        transactionExchangeRatePair
            .take(1)
            .asSingle()
            .map(\.inverseExchangeRate)
    }
}

extension PrimitiveSequence where Trait == SingleTrait, Element == PendingTransaction {

    /// Checks if `pendingOrdersLimitReached` error occured and passes that down the stream, otherwise
    ///  - in case the error is not a `NabuNetworkError` it throws the erro
    ///  - if the error is a `NabuNetworkError` and it is not a `pendingOrdersLimitReached`,
    ///    it passes a `nabuError` which contains the raw nabu error
    /// - Parameter initialValue: The current `PendingTransaction` to be updated
    /// - Returns: An `Single<PendingTransaction>` with updated `validationState`
    func handlePendingOrdersError(initialValue: PendingTransaction) -> Single<PendingTransaction> {
        `catch` { error -> Single<PendingTransaction> in
            guard let networkError = error as? NabuNetworkError else {
                throw error
            }
            guard case .nabuError(let nabuError) = networkError else {
                throw error
            }
            guard nabuError.code == .pendingOrdersLimitReached else {
                var initialValue = initialValue
                initialValue.validationState = .nabuError(nabuError)
                return .just(initialValue)
            }
            var initialValue = initialValue
            initialValue.validationState = .pendingOrdersLimitReached
            return .just(initialValue)
        }
    }
}
