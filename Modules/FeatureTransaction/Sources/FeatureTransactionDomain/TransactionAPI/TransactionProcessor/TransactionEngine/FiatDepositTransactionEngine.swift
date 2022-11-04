// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import DIKit
import Errors
import FeaturePlaidDomain
import MoneyKit
import PlatformKit
import RxSwift
import ToolKit

final class FiatDepositTransactionEngine: TransactionEngine {

    var fiatExchangeRatePairs: Observable<TransactionMoneyValuePairs> {
        .empty()
    }

    let currencyConversionService: CurrencyConversionServiceAPI
    let walletCurrencyService: FiatCurrencyServiceAPI

    let canTransactFiat: Bool = true
    var askForRefreshConfirmation: AskForRefreshConfirmation!
    var sourceAccount: BlockchainAccount!
    var transactionTarget: TransactionTarget!

    var sourceBankAccount: PlatformKit.LinkedBankAccount! {
        sourceAccount as? PlatformKit.LinkedBankAccount
    }

    var target: FiatAccount { transactionTarget as! FiatAccount }
    var targetAsset: FiatCurrency { target.fiatCurrency }
    var sourceAsset: FiatCurrency { sourceBankAccount.fiatCurrency }

    // MARK: - Private Properties

    private let app: AppProtocol
    private let paymentMethodsService: PaymentMethodTypesServiceAPI
    private let transactionLimitsService: TransactionLimitsServiceAPI
    private let bankTransferRepository: BankTransferRepositoryAPI
    private let plaidRepository: PlaidRepositoryAPI

    // MARK: - Init

    init(
        app: AppProtocol = resolve(),
        walletCurrencyService: FiatCurrencyServiceAPI = resolve(),
        currencyConversionService: CurrencyConversionServiceAPI = resolve(),
        paymentMethodsService: PaymentMethodTypesServiceAPI = resolve(),
        transactionLimitsService: TransactionLimitsServiceAPI = resolve(),
        bankTransferRepository: BankTransferRepositoryAPI = resolve(),
        plaidRepository: PlaidRepositoryAPI = resolve()
    ) {
        self.app = app
        self.walletCurrencyService = walletCurrencyService
        self.currencyConversionService = currencyConversionService
        self.transactionLimitsService = transactionLimitsService
        self.paymentMethodsService = paymentMethodsService
        self.bankTransferRepository = bankTransferRepository
        self.plaidRepository = plaidRepository
    }

    // MARK: - TransactionEngine

    func assertInputsValid() {
        precondition(sourceAccount is PlatformKit.LinkedBankAccount)
        precondition(transactionTarget is FiatAccount)
    }

    func initializeTransaction() -> Single<PendingTransaction> {
        fetchBankTransferLimits(fiatCurrency: target.fiatCurrency)
            .map { [sourceAsset, target] paymentLimits -> PendingTransaction in
                PendingTransaction(
                    amount: .zero(currency: sourceAsset),
                    available: paymentLimits.maximum ?? .zero(currency: sourceAsset),
                    feeAmount: .zero(currency: sourceAsset),
                    feeForFullAvailable: .zero(currency: sourceAsset),
                    feeSelection: .init(selectedLevel: .none, availableLevels: []),
                    selectedFiatCurrency: target.fiatCurrency,
                    limits: paymentLimits
                )
            }
    }

    func doBuildConfirmations(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {

        .just(pendingTransaction
            .update(
                confirmations: [
                    TransactionConfirmations.Source(value: sourceAccount.label),
                    TransactionConfirmations.Destination(value: target.label),
                    TransactionConfirmations.FiatTransactionFee(fee: pendingTransaction.feeAmount),
                    TransactionConfirmations.FundsArrivalDate.default,
                    TransactionConfirmations.Total(total: pendingTransaction.amount)
                ]
            )
        )
    }

    func update(amount: MoneyValue, pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        .just(pendingTransaction.update(amount: amount))
    }

    private func validateSourceBankAccountStatus(
        pendingTransaction: PendingTransaction
    ) -> Single<PendingTransaction> {
        guard app.state.yes(if: blockchain.ux.payment.method.plaid.is.available) else {
            return .just(pendingTransaction)
        }
        let accountId = sourceBankAccount.accountId
        return plaidRepository
            .getSettlementInfo(
                accountId: accountId,
                amount: pendingTransaction.amount
            )
            .asSingle()
            .flatMap { info in
                if let ux = info.error {
                    return .error(UX.Error(nabu: ux))
                }
                if let ux = info.settlement.reason?.uxError(accountId) {
                    return .error(ux)
                }
                return .just(pendingTransaction)
            }
    }

    func doValidateAll(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        validateAmount(pendingTransaction: pendingTransaction)
            .flatMap(weak: self) { (self, pendingTransaction) in
                self.validateSourceBankAccountStatus(pendingTransaction: pendingTransaction)
            }
            .updateTxValiditySingle(pendingTransaction: pendingTransaction)
    }

    func execute(pendingTransaction: PendingTransaction) -> Single<TransactionResult> {
        sourceAccount
            .receiveAddress
            .asSingle()
            .map(\.address)
            .flatMap(weak: self) { (self, identifier) -> Single<String> in
                self.bankTransferRepository
                    .startBankTransfer(
                        id: identifier,
                        amount: pendingTransaction.amount
                    )
                    .map(\.paymentId)
                    .asObservable()
                    .asSingle()
            }
            .map { TransactionResult.hashed(txHash: $0, amount: pendingTransaction.amount) }
    }

    func doUpdateFeeLevel(
        pendingTransaction: PendingTransaction,
        level: FeeLevel,
        customFeeAmount: MoneyValue
    ) -> Single<PendingTransaction> {
        .just(pendingTransaction)
    }

    // MARK: - Private Functions

    private func fetchBankTransferLimits(fiatCurrency: FiatCurrency) -> Single<TransactionLimits> {
        paymentMethodsService
            .eligiblePaymentMethods(for: fiatCurrency)
            .map { paymentMethodTypes -> PaymentMethodType? in
                paymentMethodTypes.first(where: {
                    $0.isSuggested && $0.method == .bankAccount(fiatCurrency.currencyType)
                        || $0.isSuggested && $0.method == .bankTransfer(fiatCurrency.currencyType)
                })
            }
            .flatMap { [transactionLimitsService] paymentMethodType -> Single<TransactionLimits> in
                guard case .suggested(let paymentMethod) = paymentMethodType else {
                    return .just(TransactionLimits.zero(for: fiatCurrency.currencyType))
                }
                return transactionLimitsService.fetchLimits(
                    for: paymentMethod,
                    targetCurrency: fiatCurrency.currencyType,
                    limitsCurrency: fiatCurrency.currencyType,
                    product: .simplebuy
                )
                .asSingle()
            }
    }
}
