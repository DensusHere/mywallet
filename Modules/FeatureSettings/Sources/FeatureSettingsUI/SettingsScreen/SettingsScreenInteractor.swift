// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureSettingsDomain
import PlatformKit
import PlatformUIKit
import RxSwift
import ToolKit

final class SettingsScreenInteractor {

    // MARK: - Interactors

    let emailVerificationBadgeInteractor: EmailVerificationBadgeInteractor
    let mobileVerificationBadgeInteractor: MobileVerificationBadgeInteractor
    let twoFactorVerificationBadgeInteractor: TwoFactorVerificationBadgeInteractor
    let preferredCurrencyBadgeInteractor: PreferredCurrencyBadgeInteractor
    let preferredTradingCurrencyBadgeInteractor: PreferredTradingCurrencyBadgeInteractor
    let cardSectionInteractor: CardSettingsSectionInteractor
    let bankSectionInteractor: BanksSettingsSectionInteractor
    let cardIssuingBadgeInteractor: CardIssuingBadgeInteractor
    let cardIssuingAdapter: CardIssuingAdapterAPI
    let referralAdapter: ReferralAdapterAPI

    // MARK: - Services

    // TODO: All interactors should be created inside this class,
    /// and services should be injected into them through the main class.
    /// The presenter should not contain any interaction logic

    let settingsService: SettingsServiceAPI
    let smsTwoFactorService: SMSTwoFactorSettingsServiceAPI
    let emailNotificationsService: EmailNotificationSettingsServiceAPI

    let tiersProviding: TierLimitsProviding
    let settingsAuthenticating: AppSettingsAuthenticating
    let biometryProviding: BiometryProviding
    let credentialsStore: CredentialsStoreAPI
    let recoveryPhraseStatusProvider: RecoveryPhraseStatusProviding
    let authenticationCoordinator: AuthenticationCoordinating

    // MARK: - Private Properties

    private let disposeBag = DisposeBag()

    init(
        credentialsStore: CredentialsStoreAPI = resolve(),
        settingsService: SettingsServiceAPI = resolve(),
        smsTwoFactorService: SMSTwoFactorSettingsServiceAPI = resolve(),
        emailNotificationService: EmailNotificationSettingsServiceAPI = resolve(),
        fiatCurrencyService: FiatCurrencySettingsServiceAPI = resolve(),
        settingsAuthenticating: AppSettingsAuthenticating = resolve(),
        tiersProviding: TierLimitsProviding = resolve(),
        paymentMethodTypesService: PaymentMethodTypesServiceAPI,
        authenticationCoordinator: AuthenticationCoordinating,
        cardIssuingAdapter: CardIssuingAdapterAPI = resolve(),
        referralAdapter: ReferralAdapterAPI = resolve(),
        recoveryPhraseStatusProvider: RecoveryPhraseStatusProviding = resolve()
    ) {
        self.smsTwoFactorService = smsTwoFactorService
        self.settingsService = settingsService
        emailNotificationsService = emailNotificationService
        self.tiersProviding = tiersProviding
        self.cardIssuingAdapter = cardIssuingAdapter
        self.referralAdapter = referralAdapter

        cardSectionInteractor = CardSettingsSectionInteractor(
            paymentMethodTypesService: paymentMethodTypesService,
            tierLimitsProvider: tiersProviding
        )

        bankSectionInteractor = BanksSettingsSectionInteractor(
            paymentMethodTypesService: paymentMethodTypesService,
            tierLimitsProvider: tiersProviding
        )

        emailVerificationBadgeInteractor = EmailVerificationBadgeInteractor(
            service: settingsService
        )
        mobileVerificationBadgeInteractor = MobileVerificationBadgeInteractor(
            service: settingsService
        )
        twoFactorVerificationBadgeInteractor = TwoFactorVerificationBadgeInteractor(
            service: settingsService
        )
        preferredCurrencyBadgeInteractor = PreferredCurrencyBadgeInteractor()
        preferredTradingCurrencyBadgeInteractor = PreferredTradingCurrencyBadgeInteractor()
        cardIssuingBadgeInteractor = CardIssuingBadgeInteractor(
            service: settingsService
        )

        biometryProviding = BiometryProvider(settings: settingsAuthenticating)
        self.settingsAuthenticating = settingsAuthenticating
        self.recoveryPhraseStatusProvider = recoveryPhraseStatusProvider
        self.credentialsStore = credentialsStore
        self.authenticationCoordinator = authenticationCoordinator
    }

    func refresh() {
        recoveryPhraseStatusProvider.fetchTriggerSubject.send(())
        tiersProviding.fetchTriggerRelay.accept(())
        settingsService.fetch(force: true)
            .subscribe()
            .disposed(by: disposeBag)
        bankSectionInteractor.refresh()
    }
}
