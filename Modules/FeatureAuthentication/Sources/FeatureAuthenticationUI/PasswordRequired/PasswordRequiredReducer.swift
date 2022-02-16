// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
import DIKit
import FeatureAuthenticationDomain
import Localization
import ToolKit
import WalletPayloadKit

// MARK: - Type

private enum PasswordRequiredCancellations {
    struct RequestSharedKeyId: Hashable {}
    struct RevokeTokenId: Hashable {}
    struct UpdateMobileSetupId: Hashable {}
    struct VerifyCloudBackupId: Hashable {}
}

private typealias LocalizedString = LocalizationConstants.FeatureAuthentication.PasswordRequired

public enum PasswordRequiredAction: Equatable, BindableAction {
    public enum AlertAction: Equatable {
        case show(title: String, message: String)
        case dismiss
    }

    case alert(AlertAction)
    case binding(BindingAction<PasswordRequiredState>)
    case start
    case continueButtonTapped
    case authenticate(String)
    case forgetWalletTapped
    case forgetWallet
    case forgotPasswordTapped
    case openExternalLink(URL)
}

// MARK: - Properties

public struct PasswordRequiredState: Equatable {

    // MARK: - Alert

    var alert: AlertState<PasswordRequiredAction>?

    // MARK: - Constant Info

    public var walletIdentifier: String

    // MARK: - User Input

    @BindableState public var password: String = ""
    @BindableState public var isPasswordVisible: Bool = false
    @BindableState public var isPasswordSelected: Bool = false

    public init(
        walletIdentifier: String
    ) {
        self.walletIdentifier = walletIdentifier
    }
}

public struct PasswordRequiredEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let externalAppOpener: ExternalAppOpener
    let walletPayloadService: WalletPayloadServiceAPI
    let walletManager: WalletManagerAPI
    let pushNotificationsRepository: PushNotificationsRepositoryAPI
    let mobileAuthSyncService: MobileAuthSyncServiceAPI
    let forgetWalletService: ForgetWalletService

    public init(
        mainQueue: AnySchedulerOf<DispatchQueue>,
        externalAppOpener: ExternalAppOpener,
        walletPayloadService: WalletPayloadServiceAPI,
        walletManager: WalletManagerAPI,
        pushNotificationsRepository: PushNotificationsRepositoryAPI,
        mobileAuthSyncService: MobileAuthSyncServiceAPI,
        forgetWalletService: ForgetWalletService
    ) {
        self.mainQueue = mainQueue
        self.externalAppOpener = externalAppOpener
        self.walletPayloadService = walletPayloadService
        self.walletManager = walletManager
        self.pushNotificationsRepository = pushNotificationsRepository
        self.mobileAuthSyncService = mobileAuthSyncService
        self.forgetWalletService = forgetWalletService
    }
}

public let passwordRequiredReducer = Reducer<
    PasswordRequiredState,
    PasswordRequiredAction,
    PasswordRequiredEnvironment
        // swiftlint:disable closure_body_length
> { state, action, environment in

    switch action {
    case .alert(.show(let title, let message)):
        state.alert = AlertState(
            title: TextState(verbatim: title),
            message: TextState(verbatim: message),
            dismissButton: .default(
                TextState(verbatim: LocalizationConstants.okString),
                action: .send(.alert(.dismiss))
            )
        )
        return .none
    case .alert(.dismiss):
        state.alert = nil
        return .none
    case .binding:
        return .none
    case .start:
        return .none
    case .continueButtonTapped:
        return environment
            .walletPayloadService
            .requestUsingSharedKey()
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .cancellable(id: PasswordRequiredCancellations.RequestSharedKeyId())
            .map { [state] result -> PasswordRequiredAction in
                switch result {
                case .success:
                    return .authenticate(state.password)
                case .failure:
                    return .alert(.show(
                        title: LocalizationConstants.Authentication.failedToLoadWallet,
                        message: LocalizationConstants.Errors.errorLoadingWalletIdentifierFromKeychain
                    ))
                }
            }
    case .authenticate:
        return .none
    case .forgetWalletTapped:
        state.alert = AlertState(
            title: TextState(verbatim: LocalizedString.ForgetWalletAlert.title),
            message: TextState(verbatim: LocalizedString.ForgetWalletAlert.message),
            primaryButton: .destructive(
                TextState(verbatim: LocalizedString.ForgetWalletAlert.forgetButton),
                action: .send(.forgetWallet)
            ),
            secondaryButton: .cancel(
                TextState(verbatim: LocalizationConstants.cancel),
                action: .send(.alert(.dismiss))
            )
        )
        return .none
    case .forgetWallet:
        environment.walletManager.forgetWallet()
        environment.forgetWalletService.forget()
        return .merge(
            environment
                .pushNotificationsRepository
                .revokeToken()
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .cancellable(id: PasswordRequiredCancellations.RevokeTokenId())
                .fireAndForget(),
            environment
                .mobileAuthSyncService
                .updateMobileSetup(isMobileSetup: false)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .cancellable(id: PasswordRequiredCancellations.UpdateMobileSetupId())
                .fireAndForget(),
            environment
                .mobileAuthSyncService
                .verifyCloudBackup(hasCloudBackup: false)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .cancellable(id: PasswordRequiredCancellations.VerifyCloudBackupId())
                .fireAndForget()
        )
    case .forgotPasswordTapped:
        return Effect(value: .openExternalLink(
            URL(string: Constants.SupportURL.ForgotPassword.supportLink)!
        ))
    case .openExternalLink(let url):
        environment.externalAppOpener.open(url)
        return .none
    }
}
.binding()
