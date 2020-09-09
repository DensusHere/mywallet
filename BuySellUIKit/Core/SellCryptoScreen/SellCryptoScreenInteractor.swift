//
//  SellCryptoScreenInteractor.swift
//  BuySellUIKit
//
//  Created by Daniel on 05/08/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import BuySellKit
import PlatformKit
import PlatformUIKit
import RxSwift
import RxRelay

public struct SellCryptoInteractionData {

    // TODO: Daniel - Remove and replace with a real account
    struct AnyAccount {
        let id: String
        let currencyType: CurrencyType
    }
    
    let source: AnyAccount
    let destination: AnyAccount
}

final class SellCryptoScreenInteractor: EnterAmountScreenInteractor {

    // MARK: - Types
    
    enum State {
        case inBounds(data: CandidateOrderDetails)
        case tooHigh(max: MoneyValue)
        case empty
                
        var isValid: Bool {
            switch self {
            case .inBounds:
                return true
            default:
                return false
            }
        }
        
        var isEmpty: Bool {
            switch self {
            case .empty:
                return true
            default:
                return false
            }
        }
    }
    
    override var selectedCurrencyType: Observable<CurrencyType> {
        .just(data.source.currencyType)
    }
    
    override var hasValidState: Observable<Bool> {
        stateRelay.map { $0.isValid }
    }
    
    var state: Observable<State> {
        stateRelay.asObservable()
    }
    
    /// Streams a `KycState` indicating whether the user should complete KYC
    var currentKycState: Single<Result<KycState, Error>> {
        kycTiersService.fetchTiers()
            .map { $0.isTier2Approved }
            .mapToResult(successMap: { $0 ? .completed : .shouldComplete })
    }
    
    /// Streams a boolean indicating whether the user is eligible to Simple Buy
    var currentEligibilityState: Observable<Result<Bool, Error>> {
        eligibilityService
            .fetch()
            .mapToResult()
    }
    
    /// The (optional) data, in case the state's value is `inBounds`.
    /// `nil` otherwise.
    var candidateOrderDetails: Observable<CandidateOrderDetails?> {
        state
            .map { state in
                switch state {
                case .inBounds(data: let data):
                    return data
                default:
                    return nil
                }
            }
    }

    // MARK: - Interactors
    
    let auxiliaryViewInteractor: SendAuxililaryViewInteractor
    
    // MARK: - Injected
    
    let data: SellCryptoInteractionData
    private let balanceProvider: BalanceProviding
    
    // MARK: - Accessors
    
    private let eligibilityService: EligibilityServiceAPI
    private let kycTiersService: KYCTiersServiceAPI
    private let orderCreationService: OrderCreationServiceAPI
    private let stateRelay: BehaviorRelay<State>
    private let disposeBag = DisposeBag()
    
    // MARK: - Setup
    
    init(kycTiersService: KYCTiersServiceAPI,
         eligibilityService: EligibilityServiceAPI,
         data: SellCryptoInteractionData,
         exchangeProvider: ExchangeProviding,
         balanceProvider: BalanceProviding,
         fiatCurrencyService: FiatCurrencyServiceAPI,
         cryptoCurrencySelectionService: CryptoCurrencyServiceAPI & SelectionServiceAPI,
         initialActiveInput: ActiveAmountInput,
         orderCreationService: OrderCreationServiceAPI) {
        self.eligibilityService = eligibilityService
        self.kycTiersService = kycTiersService
        self.orderCreationService = orderCreationService
        self.data = data
        self.balanceProvider = balanceProvider
        stateRelay = BehaviorRelay(value: .empty)
        auxiliaryViewInteractor = SendAuxililaryViewInteractor(
            balanceProvider: balanceProvider,
            currencyType: data.source.currencyType
        )
                
        super.init(
            exchangeProvider: exchangeProvider,
            fiatCurrencyService: fiatCurrencyService,
            cryptoCurrencySelectionService: cryptoCurrencySelectionService,
            initialActiveInput: initialActiveInput
        )
    }
    
    override func didLoad() {
        let sourceAccount = self.data.source
        let sourceAccountCurrency = sourceAccount.currencyType
        let destinationAccountCurrency = data.destination.currencyType
        let exchangeProvider = self.exchangeProvider
        let amountTranslationInteractor = self.amountTranslationInteractor

        let balance = balanceProvider[sourceAccountCurrency]
            .calculationState
            .compactMap { state -> MoneyValuePair? in
                switch state {
                case .value(let pairs):
                    return pairs[.custodial(.trading)]
                case .calculating, .invalid:
                    return nil
                }
            }
            .share(replay: 1)
        
        auxiliaryViewInteractor.resetToMaxAmount
            .withLatestFrom(balance)
            .map { ($0.base, $0.quote) }
            .map { (base, quote) -> State in
                guard !quote.isZero else { return .empty }
                guard let fiat = quote.fiatValue else { return .empty }
                guard let crypto = base.cryptoValue else { return .empty }

                let data = CandidateOrderDetails.sell(
                    fiatValue: fiat,
                    destinationFiatCurrency: destinationAccountCurrency.fiatCurrency!,
                    cryptoValue: crypto
                )
                return .inBounds(data: data)
            }
            .bindAndCatch(to: stateRelay)
            .disposed(by: disposeBag)
        
        Observable
            .combineLatest(
                amountTranslationInteractor.fiatAmount,
                amountTranslationInteractor.cryptoAmount,
                balance,
                fiatCurrencyService.fiatCurrencyObservable
            )
            .map { (fiatAmount, cryptoAmount, balance, fiatCurrency) -> State in
                guard !fiatAmount.isZero else {
                    return .empty
                }
                guard try fiatAmount <= balance.quote else {
                    return .tooHigh(max: balance.quote)
                }
                guard let fiat = fiatAmount.fiatValue else {
                    return .empty
                }
                guard let crypto = cryptoAmount.cryptoValue else {
                    return .empty
                }
                let data = CandidateOrderDetails.sell(
                    fiatValue: fiat,
                    destinationFiatCurrency: destinationAccountCurrency.fiatCurrency!,
                    cryptoValue: crypto
                )
                return .inBounds(data: data)
            }
            .bindAndCatch(to: stateRelay)
            .disposed(by: disposeBag)
        
        state
            .flatMapLatest { state -> Observable<AmountTranslationInteractor.State> in
                amountTranslationInteractor.activeInputRelay
                    .take(1)
                    .asSingle()
                    .flatMap { activeInput -> Single<AmountTranslationInteractor.State> in
                        switch state {
                        case .tooHigh(max: let moneyValue):
                            return exchangeProvider[sourceAccountCurrency].fiatPrice
                                .take(1)
                                .asSingle()
                                 .map { exchangeRate -> MoneyValuePair in
                                    MoneyValuePair(
                                        fiat: moneyValue.fiatValue!,
                                        priceInFiat: exchangeRate,
                                        cryptoCurrency: sourceAccountCurrency.cryptoCurrency!,
                                        usesFiatAsBase: activeInput == .fiat
                                    )
                                 }
                                .map { pair -> AmountTranslationInteractor.State in
                                    switch state {
                                    case .tooHigh:
                                        return .maxLimitExceeded(pair)
                                    case .empty:
                                        return .empty
                                    case .inBounds:
                                        return .inBounds
                                    }
                                }
                        case .empty:
                            return .just(.empty)
                        case .inBounds:
                            return .just(.inBounds)
                        }
                    }
                    .asObservable()
            }
            .bindAndCatch(to: amountTranslationInteractor.stateRelay)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    
    func createOrder(from candidate: CandidateOrderDetails) -> Single<CheckoutData> {
        orderCreationService.create(using: candidate)
    }
}
