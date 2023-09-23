// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
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

    @BindingState public var password: String = ""
    @BindingState public var isPasswordVisible: Bool = false
    @BindingState public var isPasswordSelected: Bool = false

    public init(
        walletIdentifier: String
    ) {
        self.walletIdentifier = walletIdentifier
    }
}

public struct PasswordRequiredReducer: ReducerProtocol {

    public typealias State = PasswordRequiredState
    public typealias Action = PasswordRequiredAction
    
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let externalAppOpener: ExternalAppOpener
    let walletPayloadService: WalletPayloadServiceAPI
    let pushNotificationsRepository: PushNotificationsRepositoryAPI
    let mobileAuthSyncService: MobileAuthSyncServiceAPI
    let forgetWalletService: ForgetWalletService

    public init(
        mainQueue: AnySchedulerOf<DispatchQueue>,
        externalAppOpener: ExternalAppOpener,
        walletPayloadService: WalletPayloadServiceAPI,
        pushNotificationsRepository: PushNotificationsRepositoryAPI,
        mobileAuthSyncService: MobileAuthSyncServiceAPI,
        forgetWalletService: ForgetWalletService
    ) {
        self.mainQueue = mainQueue
        self.externalAppOpener = externalAppOpener
        self.walletPayloadService = walletPayloadService
        self.pushNotificationsRepository = pushNotificationsRepository
        self.mobileAuthSyncService = mobileAuthSyncService
        self.forgetWalletService = forgetWalletService
    }

    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce { state, action in
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
                return walletPayloadService
                    .requestUsingSharedKey()
                    .receive(on: mainQueue)
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
                return .merge(
                    forgetWalletService
                        .forget()
                        .receive(on: mainQueue)
                        .catchToEffect()
                        .fireAndForget(),
                    pushNotificationsRepository
                        .revokeToken()
                        .receive(on: mainQueue)
                        .catchToEffect()
                        .cancellable(id: PasswordRequiredCancellations.RevokeTokenId())
                        .fireAndForget(),
                    mobileAuthSyncService
                        .updateMobileSetup(isMobileSetup: false)
                        .receive(on: mainQueue)
                        .catchToEffect()
                        .cancellable(id: PasswordRequiredCancellations.UpdateMobileSetupId())
                        .fireAndForget(),
                    mobileAuthSyncService
                        .verifyCloudBackup(hasCloudBackup: false)
                        .receive(on: mainQueue)
                        .catchToEffect()
                        .cancellable(id: PasswordRequiredCancellations.VerifyCloudBackupId())
                        .fireAndForget()
                )
            case .forgotPasswordTapped:
                return .merge(
                    EffectTask(value: .openExternalLink(
                       URL(string: Constants.HostURL.recoverPassword)!
                   )),
                    EffectTask(value: .forgetWallet)
                )
            case .openExternalLink(let url):
                externalAppOpener.open(url)
                return .none
            }
        }
    }
}
