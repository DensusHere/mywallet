// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Combine
import ComposableArchitecture
import FeatureAppDomain
import FeatureAppUpgradeDomain
import FeatureAppUpgradeUI
import FeatureAuthenticationDomain
import FeatureAuthenticationUI
import FeatureSettingsDomain
import PlatformKit
import PlatformUIKit
import ToolKit
import WalletPayloadKit

public enum Onboarding {
    public enum Alert: Equatable {
        case proceedToLoggedIn(ProceedToLoggedInError)
        case walletAuthentication(AuthenticationError)
        case walletCreation(WalletCreationServiceError)
        case walletRecovery(WalletRecoveryError)
    }

    public enum Action: Equatable {
        case start
        case showAppUpgrade(AppUpgradeState)
        case proceedToFlow
        case pin(PinCore.Action)
        case appUpgrade(AppUpgradeAction)
        case walletUpgrade(WalletUpgrade.Action)
        case passwordScreen(PasswordRequiredAction)
        case welcomeScreen(WelcomeAction)
        /// Used to change state on sub-reducers
        case handleWalletDecryptionError
        case handleMetadataRecoveryAfterAuthentication
        case informSecondPasswordDetected
        case informForWalletInitialization
        case forgetWallet
    }

    public struct State: Equatable {
        public var pinState: PinCore.State?
        public var appUpgradeState: AppUpgradeState?
        public var walletUpgradeState: WalletUpgrade.State?
        public var passwordRequiredState: PasswordRequiredState?
        public var welcomeState: WelcomeState?
        public var displayAlert: Alert?
        public var deeplinkContent: URIContent?
        public var walletCreationContext: WalletCreationContext?
        public var walletRecoveryContext: WalletRecoveryContext?

        public init(
            pinState: PinCore.State? = nil,
            appUpgradeState: AppUpgradeState? = nil,
            walletUpgradeState: WalletUpgrade.State? = nil,
            passwordRequiredState: PasswordRequiredState? = nil,
            welcomeState: WelcomeState? = nil,
            displayAlert: Alert? = nil,
            deeplinkContent: URIContent? = nil,
            walletCreationContext: WalletCreationContext? = nil
        ) {
            self.pinState = pinState
            self.appUpgradeState = appUpgradeState
            self.walletUpgradeState = walletUpgradeState
            self.passwordRequiredState = passwordRequiredState
            self.welcomeState = welcomeState
            self.displayAlert = displayAlert
            self.deeplinkContent = deeplinkContent
            self.walletCreationContext = walletCreationContext
        }
    }

    public struct Environment {
        let app: AppProtocol
        var appSettings: BlockchainSettingsAppAPI
        var credentialsStore: CredentialsStoreAPI
        var alertPresenter: AlertViewPresenterAPI
        var mainQueue: AnySchedulerOf<DispatchQueue>
        let deviceVerificationService: DeviceVerificationServiceAPI
        let walletManager: WalletManagerAPI
        let mobileAuthSyncService: MobileAuthSyncServiceAPI
        let pushNotificationsRepository: PushNotificationsRepositoryAPI
        let walletPayloadService: WalletPayloadServiceAPI
        let featureFlagsService: FeatureFlagsServiceAPI
        let externalAppOpener: ExternalAppOpener
        let forgetWalletService: ForgetWalletService
        let recaptchaService: GoogleRecaptchaServiceAPI
        var buildVersionProvider: () -> String
        var appUpgradeState: () -> AnyPublisher<AppUpgradeState?, Never>
    }
}

/// The reducer responsible for handing Pin screen and Login/Onboarding screen related action and state.
let onBoardingReducer = Reducer<Onboarding.State, Onboarding.Action, Onboarding.Environment>.combine(
    welcomeReducer
        .optional()
        .pullback(
            state: \.welcomeState,
            action: /Onboarding.Action.welcomeScreen,
            environment: {
                WelcomeEnvironment(
                    app: $0.app,
                    mainQueue: $0.mainQueue,
                    deviceVerificationService: $0.deviceVerificationService,
                    featureFlagsService: $0.featureFlagsService,
                    recaptchaService: $0.recaptchaService,
                    buildVersionProvider: $0.buildVersionProvider,
                    nativeWalletEnabled: { nativeWalletFlagEnabled() }
                )
            }
        ),
    pinReducer
        .optional()
        .pullback(
            state: \.pinState,
            action: /Onboarding.Action.pin,
            environment: {
                PinCore.Environment(
                    appSettings: $0.appSettings,
                    alertPresenter: $0.alertPresenter
                )
            }
        ),
    passwordRequiredReducer
        .optional()
        .pullback(
            state: \.passwordRequiredState,
            action: /Onboarding.Action.passwordScreen,
            environment: {
                PasswordRequiredEnvironment(
                    mainQueue: $0.mainQueue,
                    externalAppOpener: $0.externalAppOpener,
                    walletPayloadService: $0.walletPayloadService,
                    walletManager: $0.walletManager,
                    pushNotificationsRepository: $0.pushNotificationsRepository,
                    mobileAuthSyncService: $0.mobileAuthSyncService,
                    forgetWalletService: $0.forgetWalletService
                )
            }
        ),
    walletUpgradeReducer
        .optional()
        .pullback(
            state: \.walletUpgradeState,
            action: /Onboarding.Action.walletUpgrade,
            environment: { _ in
                WalletUpgrade.Environment()
            }
        ),
    appUpgradeReducer
        .optional()
        .pullback(
            state: \.appUpgradeState,
            action: /Onboarding.Action.appUpgrade,
            environment: { _ in
                ()
            }
        ),
    // swiftlint:disable closure_body_length
    Reducer<Onboarding.State, Onboarding.Action, Onboarding.Environment> { state, action, environment in
        switch action {
        case .showAppUpgrade(let appUpgradeState):
            state.appUpgradeState = appUpgradeState
            return .none
        case .appUpgrade(.skip):
            return Effect(value: .proceedToFlow)
        case .start:
            return environment.appUpgradeState()
                .eraseToEffect()
                .map { state in
                    guard let state = state else {
                        return .proceedToFlow
                    }
                    return .showAppUpgrade(state)
                }
        case .proceedToFlow:
            return decideFlow(
                state: &state,
                appSettings: environment.appSettings
            )
        case .pin:
            return .none

        case .welcomeScreen(.route(nil)):
            // don't clear the state if the state is .new when dismissing the modal by setting the screen flow back to welcome screen
            if state.walletCreationContext == .existing || state.walletCreationContext == .recovery {
                state.walletCreationContext = nil
            }
            return .none

        case .welcomeScreen(.navigate(to: .createWallet)),
             .welcomeScreen(.enter(into: .createWallet)):
            state.walletCreationContext = .new
            return .none

        case .welcomeScreen(.enter(into: .emailLogin)):
            state.walletCreationContext = .existing
            return .none

        case .welcomeScreen(.enter(into: .restoreWallet)):
            state.walletCreationContext = .recovery
            return .none
        case .welcomeScreen(.requestedToRestoreWallet(let walletRecovery)):
            switch walletRecovery {
            case .metadataRecovery(let seedPhrase):
                state.walletRecoveryContext = .metadataRecovery
                return .none
            case .importRecovery:
                state.walletRecoveryContext = .importRecovery
                return .none
            case .resetAccountRecovery(let email, let newPassword, let nabuInfo):
                return .none
            }
        case .welcomeScreen(.informForWalletInitialization):
            return Effect(value: .informForWalletInitialization)
        case .welcomeScreen:
            return .none
        case .walletUpgrade(.begin):
            return .none
        case .walletUpgrade:
            return .none
        case .passwordScreen(.forgetWallet),
             .forgetWallet:
            state.passwordRequiredState = nil
            state.pinState = nil
            state.welcomeState = .init()
            environment.appSettings.clear()
            environment.credentialsStore.erase()
            return Effect(value: .welcomeScreen(.start))
        case .passwordScreen:
            return .none
        case .informSecondPasswordDetected:
            guard state.welcomeState != nil else {
                return .none
            }
            return Effect(value: .welcomeScreen(.informSecondPasswordDetected))

        case .informForWalletInitialization:
            return .none
        case .handleWalletDecryptionError:
            if state.welcomeState?.manualCredentialsState != nil {
                return Effect(
                    value: .welcomeScreen(
                        .manualPairing(
                            .password(
                                .showIncorrectPasswordError(true)
                            )
                        )
                    )
                )
            }
            return Effect(
                value: .welcomeScreen(
                    .emailLogin(
                        .verifyDevice(
                            .credentials(
                                .password(
                                    .showIncorrectPasswordError(true)
                                )
                            )
                        )
                    )
                )
            )
        case .handleMetadataRecoveryAfterAuthentication:
            // if it is from the restore wallet screen
            if state.welcomeState?.restoreWalletState != nil {
                return .merge(
                    Effect(value: .welcomeScreen(.restoreWallet(.setResetPasswordScreenVisible(true))))
                )
                // if it is from the trouble logging in screen
            } else if state.welcomeState?.emailLoginState != nil {
                return .merge(
                    Effect(
                        value: .welcomeScreen(
                            .emailLogin(
                                .verifyDevice(
                                    .credentials(
                                        .seedPhrase(
                                            .setResetPasswordScreenVisible(true))
                                    )
                                )
                            )
                        )
                    )
                )
            }
            return .none
        }
    }
    // swiftlint:enable closure_body_length
)

// MARK: - Internal Methods

func decideFlow(
    state: inout Onboarding.State,
    appSettings: BlockchainSettingsAppAPI
) -> Effect<Onboarding.Action, Never> {
    state.appUpgradeState = nil
    if appSettings.guid != nil, appSettings.sharedKey != nil {
        // Original flow
        if appSettings.isPinSet {
            state.pinState = .init()
            state.passwordRequiredState = nil
            return Effect(value: .pin(.authenticate))
        } else {
            state.pinState = nil
            state.passwordRequiredState = .init(
                walletIdentifier: appSettings.guid ?? ""
            )
            return Effect(value: .passwordScreen(.start))
        }
    } else if appSettings.pinKey != nil, appSettings.encryptedPinPassword != nil {
        // iCloud restoration flow
        if appSettings.isPinSet {
            state.pinState = .init()
            state.passwordRequiredState = nil
            return Effect(value: .pin(.authenticate))
        } else {
            state.pinState = nil
            state.passwordRequiredState = .init(
                walletIdentifier: appSettings.guid ?? ""
            )
            return Effect(value: .passwordScreen(.start))
        }
    } else {
        state.pinState = nil
        state.passwordRequiredState = nil
        state.welcomeState = .init()
        return Effect(value: .welcomeScreen(.start))
    }
}
