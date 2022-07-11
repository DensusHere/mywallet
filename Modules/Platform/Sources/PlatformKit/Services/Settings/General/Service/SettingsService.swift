// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Combine
import DIKit
import FeatureAuthenticationDomain
import MoneyKit
import RxRelay
import RxSwift
import RxToolKit
import ToolKit

final class SettingsService: SettingsServiceAPI {

    // MARK: - Exposed Properties

    /// Streams the first available settings element
    var valueSingle: Single<WalletSettings> {
        valueObservable
            .take(1)
            .asSingle()
    }

    var valueObservable: Observable<WalletSettings> {
        settingsRelay
            .flatMap(weak: self) { (self, settings) -> Observable<WalletSettings> in
                guard let settings = settings else {
                    return self.fetch(force: false).asObservable()
                }
                return .just(settings)
            }
            .distinctUntilChanged()
    }

    // MARK: - Private Properties

    private let app: AppProtocol
    private let client: SettingsClientAPI
    private let credentialsRepository: CredentialsRepositoryAPI
    private let supportedPairsService: SupportedPairsServiceAPI
    private let userService: NabuUserServiceAPI

    private let settingsRelay = BehaviorRelay<WalletSettings?>(value: nil)
    private let disposeBag = DisposeBag()
    private let scheduler = SerialDispatchQueueScheduler(qos: .default)
    private let semaphore = DispatchSemaphore(value: 1)

    private var refresh: AnyCancellable?

    // MARK: - Setup

    init(
        app: AppProtocol = resolve(),
        client: SettingsClientAPI = resolve(),
        credentialsRepository: CredentialsRepositoryAPI = resolve(),
        supportedPairsService: SupportedPairsServiceAPI = resolve(),
        userService: NabuUserServiceAPI = resolve()
    ) {
        self.app = app
        self.client = client
        self.credentialsRepository = credentialsRepository
        self.supportedPairsService = supportedPairsService
        self.userService = userService

        tradingCurrencyPublisher = app.publisher(for: blockchain.user.currency.preferred.fiat.trading.currency)
            .shareReplay()
            .replaceError(with: .USD)

        displayCurrencyPublisher = app.publisher(for: blockchain.user.currency.preferred.fiat.display.currency)
            .shareReplay()
            .replaceError(with: Locale.current.currencyCode.flatMap(FiatCurrency.init(code:)) ?? .USD)

        supportedFiatCurrencies = app.publisher(for: blockchain.user.currency.available)
            .shareReplay()
            .replaceError(with: Set(MoneyKit.allEnabledFiatCurrencies))

        refresh = app.on(
            blockchain.session.event.did.sign.in,
            blockchain.session.event.did.sign.out
        ) { [weak self] _ in
            self?.settingsRelay.accept(nil)
        }
        .subscribe()
    }

    // MARK: - Public Methods

    func fetch(force: Bool) -> Single<WalletSettings> {
        Single.create(weak: self) { (self, observer) -> Disposable in
            guard case .success = self.semaphore.wait(timeout: .now() + .seconds(30)) else {
                observer(.error(ToolKitError.timedOut))
                return Disposables.create()
            }
            let disposable = self.settingsRelay
                .take(1)
                .asSingle()
                .flatMap(weak: self) { (self, settings: WalletSettings?) -> Single<WalletSettings> in
                    self.fetchSettings(settings: settings, force: force)
                }
                .subscribe { event in
                    switch event {
                    case .success(let settings):
                        observer(.success(settings))
                    case .failure(let error):
                        observer(.error(error))
                    }
                }

            return Disposables.create {
                disposable.dispose()
                self.semaphore.signal()
            }
        }
        .subscribe(on: scheduler)
    }

    private func fetchSettings(settings: WalletSettings?, force: Bool) -> Single<WalletSettings> {
        guard force || settings == nil else { return Single.just(settings!) }
        return credentialsRepository.credentials.asSingle()
            .flatMap(weak: self) { (self, credentials) in
                self.client.settings(
                    by: credentials.guid,
                    sharedKey: credentials.sharedKey
                )
                .asSingle()
            }
            .map { WalletSettings(response: $0) }
            .do(onSuccess: { [weak self] settings in
                self?.app.state.transaction { state in
                    state.set(
                        blockchain.user.currency.preferred.fiat.display.currency,
                        to: settings.displayCurrency?.code
                    )
                }
                self?.settingsRelay.accept(settings)
            })
    }

    var displayCurrencyPublisher: AnyPublisher<FiatCurrency, Never>
    var tradingCurrencyPublisher: AnyPublisher<FiatCurrency, Never>
    var supportedFiatCurrencies: AnyPublisher<Set<FiatCurrency>, Never>
}

extension SettingsService {

    // MARK: - SettingsServiceCombineAPI

    var singleValuePublisher: AnyPublisher<WalletSettings, SettingsServiceError> {
        valueSingle
            .asObservable()
            .publisher
            .mapError { error -> SettingsServiceError in
                switch error {
                case ToolKitError.timedOut:
                    return .timedOut
                default:
                    return .fetchFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }

    var valuePublisher: AnyPublisher<WalletSettings, SettingsServiceError> {
        valueObservable
            .publisher
            .mapError { error -> SettingsServiceError in
                switch error {
                case ToolKitError.timedOut:
                    return .timedOut
                default:
                    return .fetchFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }

    func fetchPublisher(force: Bool) -> AnyPublisher<WalletSettings, SettingsServiceError> {
        fetch(force: force)
            .asObservable()
            .publisher
            .mapError { error -> SettingsServiceError in
                switch error {
                case ToolKitError.timedOut:
                    return .timedOut
                default:
                    return .fetchFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - FiatCurrencySettingsServiceAPI

extension SettingsService: FiatCurrencySettingsServiceAPI {

    func update(
        displayCurrency: FiatCurrency,
        context: FlowContext
    ) -> AnyPublisher<Void, CurrencyUpdateError> {
        credentialsRepository.credentials
            .mapError(CurrencyUpdateError.credentialsError)
            .flatMap { [client] (guid: String, sharedKey: String) in
                client.updatePublisher(
                    currency: displayCurrency.code,
                    context: context,
                    guid: guid,
                    sharedKey: sharedKey
                )
            }
            .handleEvents(
                receiveOutput: { [app] in
                    app.post(
                        value: displayCurrency.code,
                        of: blockchain.user.currency.preferred.fiat.display.currency
                    )
                }
            )
            .zip(
                singleValuePublisher
                    .replaceError(with: CurrencyUpdateError.fetchError(SettingsServiceError.timedOut))
            )
            .mapToVoid()
            .eraseToAnyPublisher()
    }

    func update(
        tradingCurrency: FiatCurrency,
        context: FlowContext
    ) -> AnyPublisher<Void, CurrencyUpdateError> {
        .just(
            app.post(
                value: tradingCurrency.code,
                of: blockchain.user.currency.preferred.fiat.trading.currency
            )
        )
    }
}

// MARK: - SettingsEmailUpdateServiceAPI

extension SettingsService: EmailSettingsServiceAPI {

    var email: Single<String> {
        valueSingle.map(\.email)
    }

    var emailPublisher: AnyPublisher<String, EmailSettingsServiceError> {
        valueSingle
            .map(\.email)
            .asPublisher()
            .mapError(EmailSettingsServiceError.unknown)
            .eraseToAnyPublisher()
    }

    func update(email: String, context: FlowContext?) -> Completable {
        credentialsRepository.credentials.asSingle()
            .flatMapCompletable(weak: self) { (self, payload) -> Completable in
                self.client.update(
                    email: email,
                    context: context,
                    guid: payload.guid,
                    sharedKey: payload.sharedKey
                )
                .asObservable()
                .ignoreElements()
                .asCompletable()
            }
    }

    func update(email: String) -> AnyPublisher<String, EmailSettingsServiceError> {
        credentialsRepository.credentials
            .mapError(EmailSettingsServiceError.credentialsError)
            .flatMap { [client] guid, sharedKey in
                client.update(
                    email: email,
                    context: nil,
                    guid: guid,
                    sharedKey: sharedKey
                )
                .mapError(EmailSettingsServiceError.networkError)
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - LastTransactionSettingsUpdateServiceAPI

extension SettingsService: LastTransactionSettingsUpdateServiceAPI {
    func updateLastTransaction() -> Completable {
        credentialsRepository.credentials.asSingle()
            .flatMapCompletable(weak: self) { (self, payload) -> Completable in
                self.client.updateLastTransactionTime(
                    guid: payload.guid,
                    sharedKey: payload.sharedKey
                )
                .asObservable()
                .ignoreElements()
                .asCompletable()
            }
            .flatMapSingle(weak: self) { (self) in
                self.fetch(force: true)
            }
            .asCompletable()
    }
}

// MARK: - EmailNotificationSettingsServiceAPI

extension SettingsService: EmailNotificationSettingsServiceAPI {
    func emailNotifications(enabled: Bool) -> Completable {
        credentialsRepository.credentials.asSingle()
            .flatMapCompletable(weak: self) { (self, payload) -> Completable in
                self.client.emailNotifications(
                    enabled: enabled,
                    guid: payload.guid,
                    sharedKey: payload.sharedKey
                )
                .asObservable()
                .ignoreElements()
                .asCompletable()
            }
            .flatMapSingle(weak: self) { (self) in
                self.fetch(force: true)
            }
            .asCompletable()
    }
}

// MARK: - UpdateMobileSettingsServiceAPI

extension SettingsService: UpdateMobileSettingsServiceAPI {
    func update(mobileNumber: String) -> Completable {
        credentialsRepository.credentials.asSingle()
            .flatMapCompletable(weak: self) { (self, payload) -> Completable in
                self.client.update(
                    smsNumber: mobileNumber,
                    context: .settings,
                    guid: payload.guid,
                    sharedKey: payload.sharedKey
                )
                .asObservable()
                .ignoreElements()
                .asCompletable()
            }
            .flatMapSingle(weak: self) { (self) in
                self.fetch(force: true)
            }
            .asCompletable()
    }
}

// MARK: - VerifyMobileSettingsServiceAPI

extension SettingsService: VerifyMobileSettingsServiceAPI {
    func verify(with code: String) -> Completable {
        credentialsRepository.credentials.asSingle()
            .flatMapCompletable(weak: self) { (self, payload) -> Completable in
                self.client.verifySMS(
                    code: code,
                    guid: payload.guid,
                    sharedKey: payload.sharedKey
                )
                .asObservable()
                .ignoreElements()
                .asCompletable()
            }
            .flatMapSingle(weak: self) { (self) in
                self.fetch(force: true)
            }
            .asCompletable()
    }
}

// MARK: - SMSTwoFactorSettingsServiceAPI

extension SettingsService: SMSTwoFactorSettingsServiceAPI {
    func smsTwoFactorAuthentication(enabled: Bool) -> Completable {
        credentialsRepository.credentials.asSingle()
            .flatMapCompletable(weak: self) { (self, payload) -> Completable in
                self.client.smsTwoFactorAuthentication(
                    enabled: enabled,
                    guid: payload.guid,
                    sharedKey: payload.sharedKey
                )
                .asObservable()
                .ignoreElements()
                .asCompletable()
            }
            .flatMapSingle(weak: self) { (self) in
                self.fetch(force: true)
            }
            .asCompletable()
    }
}
