// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import BlockchainNamespace
import Combine
import ComposableArchitecture
import FeatureAuthenticationDomain
import Localization
import ToolKit
import WalletPayloadKit

// MARK: - Type

public enum WalletRecoveryIds {
    public struct RecoveryId: Hashable {}
    public struct ImportId: Hashable {}
    public struct AccountRecoveryAfterResetId: Hashable {}
    public struct WalletFetchAfterRecoveryId: Hashable {}
}

public enum SeedPhraseAction: Equatable {

    public enum URLContent {

        case contactSupport

        var url: URL? {
            switch self {
            case .contactSupport:
                return URL(string: Constants.SupportURL.ResetAccount.contactSupport)
            }
        }
    }

    public enum AlertAction: Equatable {
        case show(title: String, message: String)
        case dismiss
    }

    case alert(AlertAction)
    case didChangeSeedPhrase(String)
    case didChangeSeedPhraseScore(MnemonicValidationScore)
    case validateSeedPhrase
    case setResetPasswordScreenVisible(Bool)
    case setResetAccountBottomSheetVisible(Bool)
    case setLostFundsWarningScreenVisible(Bool)
    case setImportWalletScreenVisible(Bool)
    case setSecondPasswordNoticeVisible(Bool)
    case resetPassword(ResetPasswordAction)
    case resetAccountWarning(ResetAccountWarningAction)
    case lostFundsWarning(LostFundsWarningAction)
    case importWallet(ImportWalletAction)
    case secondPasswordNotice(SecondPasswordNoticeReducer.Action)
    case restoreWallet(WalletRecovery)
    case restored(Result<Either<EmptyValue, WalletFetchedContext>, WalletRecoveryError>)
    case imported(Result<EmptyValue, WalletRecoveryError>)
    case accountCreation(Result<WalletCreatedContext, WalletCreationServiceError>)
    case accountRecovered(AccountResetContext)
    case walletFetched(Result<Either<EmptyValue, WalletFetchedContext>, WalletFetcherServiceError>)
    case informWalletFetched(WalletFetchedContext)
    case triggerAuthenticate // needed for legacy wallet flow
    case open(urlContent: URLContent)
    case none
}

public enum AccountRecoveryContext: Equatable {
    case troubleLoggingIn
    case restoreWallet
    case none
}

public struct AccountResetContext: Equatable {
    let walletContext: WalletCreatedContext
    let offlineToken: NabuOfflineToken
}

// MARK: - Properties

public struct SeedPhraseState: Equatable {
    var context: AccountRecoveryContext
    var emailAddress: String
    var nabuInfo: WalletInfo.Nabu?
    var seedPhrase: String
    var seedPhraseScore: MnemonicValidationScore
    var isResetPasswordScreenVisible: Bool
    var isResetAccountBottomSheetVisible: Bool
    var isLostFundsWarningScreenVisible: Bool
    var isImportWalletScreenVisible: Bool
    var isSecondPasswordNoticeVisible: Bool
    var resetPasswordState: ResetPasswordState?
    var resetAccountWarningState: ResetAccountWarningState?
    var lostFundsWarningState: LostFundsWarningState?
    var importWalletState: ImportWalletState?
    var secondPasswordNoticeState: SecondPasswordNoticeReducer.State?
    var failureAlert: AlertState<SeedPhraseAction>?
    var isLoading: Bool

    var accountResettable: Bool {
        guard let nabuInfo else {
            return false
        }
        return nabuInfo.recoverable
    }

    init(context: AccountRecoveryContext, emailAddress: String = "", nabuInfo: WalletInfo.Nabu? = nil) {
        self.context = context
        self.emailAddress = emailAddress
        self.nabuInfo = nabuInfo
        self.seedPhrase = ""
        self.seedPhraseScore = .none
        self.isResetPasswordScreenVisible = false
        self.isResetAccountBottomSheetVisible = false
        self.isLostFundsWarningScreenVisible = false
        self.isImportWalletScreenVisible = false
        self.isSecondPasswordNoticeVisible = false
        self.failureAlert = nil
        self.isLoading = false
    }
}

struct SeedPhraseReducer: ReducerProtocol {

    typealias State = SeedPhraseState
    typealias Action = SeedPhraseAction

    let mainQueue: AnySchedulerOf<DispatchQueue>
    let validator: SeedPhraseValidatorAPI
    let externalAppOpener: ExternalAppOpener
    let passwordValidator: PasswordValidatorAPI
    let analyticsRecorder: AnalyticsEventRecorderAPI
    let walletRecoveryService: WalletRecoveryService
    let walletCreationService: WalletCreationService
    let walletFetcherService: WalletFetcherService
    let accountRecoveryService: AccountRecoveryServiceAPI
    let signUpCountriesService: SignUpCountriesServiceAPI
    let errorRecorder: ErrorRecording
    let recaptchaService: GoogleRecaptchaServiceAPI
    let app: AppProtocol

    init(
        mainQueue: AnySchedulerOf<DispatchQueue>,
        externalAppOpener: ExternalAppOpener,
        analyticsRecorder: AnalyticsEventRecorderAPI,
        walletRecoveryService: WalletRecoveryService,
        walletCreationService: WalletCreationService,
        walletFetcherService: WalletFetcherService,
        accountRecoveryService: AccountRecoveryServiceAPI,
        errorRecorder: ErrorRecording,
        recaptchaService: GoogleRecaptchaServiceAPI,
        validator: SeedPhraseValidatorAPI,
        passwordValidator: PasswordValidatorAPI,
        signUpCountriesService: SignUpCountriesServiceAPI,
        app: AppProtocol
    ) {
        self.mainQueue = mainQueue
        self.validator = validator
        self.passwordValidator = passwordValidator
        self.externalAppOpener = externalAppOpener
        self.analyticsRecorder = analyticsRecorder
        self.walletRecoveryService = walletRecoveryService
        self.walletCreationService = walletCreationService
        self.walletFetcherService = walletFetcherService
        self.accountRecoveryService = accountRecoveryService
        self.signUpCountriesService = signUpCountriesService
        self.errorRecorder = errorRecorder
        self.recaptchaService = recaptchaService
        self.app = app
    }

    var body: some ReducerProtocol<State, Action> {
        main
            .ifLet(\.secondPasswordNoticeState, action: /Action.secondPasswordNotice) {
                SecondPasswordNoticeReducer(
                    externalAppOpener: externalAppOpener
                )
            }
            .ifLet(\.importWalletState, action: /Action.importWallet) {
                ImportWalletReducer(
                    mainQueue: mainQueue,
                    passwordValidator: passwordValidator,
                    externalAppOpener: externalAppOpener,
                    analyticsRecorder: analyticsRecorder,
                    walletRecoveryService: walletRecoveryService,
                    walletCreationService: walletCreationService,
                    walletFetcherService: walletFetcherService,
                    signUpCountriesService: signUpCountriesService,
                    recaptchaService: recaptchaService,
                    app: app
                )
            }
            .ifLet(\.resetAccountWarningState, action: /Action.resetAccountWarning) {
                ResetAccountWarningReducer(
                    analyticsRecorder: analyticsRecorder
                )
            }
            .ifLet(\.lostFundsWarningState, action: /Action.lostFundsWarning) {
                LostFundsWarningReducer(
                    mainQueue: mainQueue,
                    analyticsRecorder: analyticsRecorder,
                    passwordValidator: passwordValidator,
                    externalAppOpener: externalAppOpener,
                    errorRecorder: errorRecorder
                )
            }
            .ifLet(\.resetPasswordState, action: /Action.resetPassword) {
                ResetPasswordReducer(
                    mainQueue: mainQueue,
                    passwordValidator: passwordValidator,
                    externalAppOpener: externalAppOpener,
                    errorRecorder: errorRecorder
                )
            }
    }

    var main: some ReducerProtocol<State, Action> { // Divide and conquer to compile.
        Reduce { state, action -> EffectTask<Action> in
            switch action {

            case .didChangeSeedPhrase(let seedPhrase):
                state.seedPhrase = seedPhrase
                return EffectTask(value: .validateSeedPhrase)

            case .didChangeSeedPhraseScore(let score):
                state.seedPhraseScore = score
                return .none

            case .validateSeedPhrase:
                return validator
                    .validate(phrase: state.seedPhrase)
                    .receive(on: mainQueue)
                    .catchToEffect()
                    .map { result -> SeedPhraseAction in
                        guard case .success(let score) = result else {
                            return .none
                        }
                        return .didChangeSeedPhraseScore(score)
                    }

            case .setResetPasswordScreenVisible(let isVisible):
                state.isResetPasswordScreenVisible = isVisible
                if isVisible {
                    state.resetPasswordState = .init()
                    analyticsRecorder.record(
                        event: .recoveryPhraseEntered
                    )
                }
                return .none

            case .setResetAccountBottomSheetVisible(let isVisible):
                state.isResetAccountBottomSheetVisible = isVisible
                if isVisible {
                    state.resetAccountWarningState = .init()
                    analyticsRecorder.record(
                        event: .resetAccountClicked
                    )
                } else {
                    analyticsRecorder.record(
                        event: .resetAccountCancelled
                    )
                }
                return .none

            case .setLostFundsWarningScreenVisible(let isVisible):
                state.isLostFundsWarningScreenVisible = isVisible
                if isVisible {
                    state.lostFundsWarningState = .init()
                    analyticsRecorder.record(
                        event: .resetAccountCancelled
                    )
                }
                return .none

            case .setImportWalletScreenVisible(let isVisible):
                state.isImportWalletScreenVisible = isVisible
                if isVisible {
                    state.importWalletState = .init(mnemonic: state.seedPhrase)
                    analyticsRecorder.record(
                        event: .recoveryPhraseEntered
                    )
                }
                return .none

            case .setSecondPasswordNoticeVisible(let isVisible):
                state.isSecondPasswordNoticeVisible = isVisible
                if isVisible {
                    state.secondPasswordNoticeState = .init()
                }
                return .none

            case .resetPassword:
                // handled in reset password reducer
                return .none

            case .resetAccountWarning(.retryButtonTapped),
                 .resetAccountWarning(.onDisappear):
                return EffectTask(value: .setResetAccountBottomSheetVisible(false))

            case .resetAccountWarning(.continueResetButtonTapped):
                return .concatenate(
                    EffectTask(value: .setResetAccountBottomSheetVisible(false)),
                    EffectTask(value: .setLostFundsWarningScreenVisible(true))
                )

            case .lostFundsWarning(.goBackButtonTapped):
                return EffectTask(value: .setLostFundsWarningScreenVisible(false))

            case .lostFundsWarning(.resetPassword(.reset(let password))):
                guard state.nabuInfo != nil else {
                    return .none
                }
                let accountName = NonLocalizedConstants.defiWalletTitle
                return .concatenate(
                    EffectTask(value: .triggerAuthenticate),
                    walletCreationService
                        .createWallet(
                            state.emailAddress,
                            password,
                            accountName,
                            nil
                        )
                        .receive(on: mainQueue)
                        .catchToEffect()
                        .cancellable(id: CreateAccountStepTwoIds.CreationId(), cancelInFlight: true)
                        .map(SeedPhraseAction.accountCreation)
                )

            case .accountCreation(.failure(let error)):
                let title = LocalizationConstants.Errors.error
                let message = error.localizedDescription
                state.lostFundsWarningState?.resetPasswordState?.isLoading = false
                return .merge(
                    EffectTask(
                        value: .alert(
                            .show(
                                title: title,
                                message: message
                            )
                        )
                    ),
                    .cancel(id: CreateAccountStepTwoIds.CreationId())
                )

            case .accountCreation(.success(let context)):
                guard let nabuInfo = state.nabuInfo else {
                    return .none
                }
                return .merge(
                    .cancel(id: CreateAccountStepTwoIds.CreationId()),
                    accountRecoveryService
                        .recoverUser(
                            guid: context.guid,
                            sharedKey: context.sharedKey,
                            userId: nabuInfo.userId,
                            recoveryToken: nabuInfo.recoveryToken
                        )
                        .receive(on: mainQueue)
                        .catchToEffect()
                        .cancellable(id: WalletRecoveryIds.AccountRecoveryAfterResetId(), cancelInFlight: false)
                        .map { result -> SeedPhraseAction in
                            guard case .success(let offlineToken) = result else {
                                analyticsRecorder.record(
                                    event: AnalyticsEvents.New.AccountRecoveryFlow.accountRecoveryFailed
                                )
                                // show recovery failures if the endpoint fails
                                return .lostFundsWarning(
                                    .resetPassword(
                                        .setResetAccountFailureVisible(true)
                                    )
                                )
                            }
                            analyticsRecorder.record(
                                event: AnalyticsEvents.New.AccountRecoveryFlow
                                    .accountPasswordReset(hasRecoveryPhrase: false)
                            )
                            return .accountRecovered(
                                AccountResetContext(
                                    walletContext: context,
                                    offlineToken: offlineToken
                                )
                            )
                        }
                )

            case .accountRecovered(let info):
                // NOTE: The effects of fetching a wallet still happen on the CoreCoordinator
                // Unfortunately Resetting an account and wallet fetching are related
                // In order to save the token wallet metadata we need
                // to have a fully loaded wallet so the following happens:
                // 1) Fetch the wallet
                // 2) Store the offlineToken to the wallet metadata
                // There's no error handling as any error will be overruled by the CoreCoordinator
                return .merge(
                    .cancel(id: WalletRecoveryIds.AccountRecoveryAfterResetId()),
                    walletFetcherService
                        .fetchWalletAfterAccountRecovery(
                            info.walletContext.guid,
                            info.walletContext.sharedKey,
                            info.walletContext.password,
                            info.offlineToken
                        )
                        .receive(on: mainQueue)
                        .catchToEffect()
                        .cancellable(id: WalletRecoveryIds.WalletFetchAfterRecoveryId())
                        .map(SeedPhraseAction.walletFetched)
                )

            case .walletFetched(.success(.left(.noValue))):
                // this is for legacy JS flow, to be removed
                return .none

            case .walletFetched(.success(.right(let context))):
                return EffectTask(value: .informWalletFetched(context))

            case .walletFetched(.failure(let error)):
                let title = LocalizationConstants.ErrorAlert.title
                let message = error.errorDescription ?? LocalizationConstants.ErrorAlert.message
                return EffectTask(
                    value: .alert(
                        .show(title: title, message: message)
                    )
                )

            case .informWalletFetched:
                // handled in WelcomeReducer
                return .none

            case .lostFundsWarning:
                return .none

            case .importWallet(.goBackButtonTapped):
                return EffectTask(value: .setImportWalletScreenVisible(false))

            case .importWallet(.createAccount(.triggerAuthenticate)):
                return EffectTask(value: .triggerAuthenticate)

            case .importWallet:
                return .none

            case .secondPasswordNotice:
                return .none

            case .restoreWallet(.metadataRecovery(let mnemonic)):
                state.isLoading = true
                return .concatenate(
                    EffectTask(value: .triggerAuthenticate),
                    walletRecoveryService
                        .recoverFromMetadata(mnemonic)
                        .receive(on: mainQueue)
                        .mapError(WalletRecoveryError.restoreFailure)
                        .catchToEffect()
                        .cancellable(id: WalletRecoveryIds.RecoveryId(), cancelInFlight: true)
                        .map(SeedPhraseAction.restored)
                )
            case .restoreWallet:
                return .none

            case .restored(.success(.left(.noValue))):
                state.isLoading = false
                return .cancel(id: WalletRecoveryIds.RecoveryId())

            case .restored(.success(.right(let context))):
                state.isLoading = false
                return .merge(
                    .cancel(id: WalletRecoveryIds.RecoveryId()),
                    EffectTask(value: .informWalletFetched(context))
                )

            case .restored(.failure(.restoreFailure(.recovery(.unableToRecoverFromMetadata)))):
                state.isLoading = false
                return .merge(
                    .cancel(id: WalletRecoveryIds.RecoveryId()),
                    EffectTask(value: .setImportWalletScreenVisible(true))
                )

            case .restored(.failure(.restoreFailure(let error))):
                state.isLoading = false
                let title = LocalizationConstants.Errors.error
                let message = error.errorDescription ?? LocalizationConstants.Errors.genericError
                return .merge(
                    .cancel(id: WalletRecoveryIds.RecoveryId()),
                    EffectTask(value: .alert(.show(title: title, message: message)))
                )

            case .imported(.success):
                return .cancel(id: WalletRecoveryIds.ImportId())

            case .imported(.failure(let error)):
                guard state.importWalletState != nil else {
                    return .none
                }
                return EffectTask(value: .importWallet(.importWalletFailed(error)))

            case .open(let urlContent):
                guard let url = urlContent.url else {
                    return .none
                }
                externalAppOpener.open(url)
                return .none

            case .triggerAuthenticate:
                return .none

            case .alert(.show(let title, let message)):
                state.failureAlert = AlertState(
                    title: TextState(verbatim: title),
                    message: TextState(verbatim: message),
                    dismissButton: .default(
                        TextState(LocalizationConstants.okString),
                        action: .send(.alert(.dismiss))
                    )
                )
                return .none

            case .alert(.dismiss):
                state.failureAlert = nil
                return .none

            case .none:
                return .none
            }
        }
    }
}
