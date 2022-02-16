// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import BlockchainComponentLibrary
import ComposableArchitecture
import FeatureAuthenticationDomain
import Localization
import SwiftUI
import ToolKit
import UIComponentsKit

// swiftlint:disable type_body_length
public struct CredentialsView: View {

    private typealias LocalizedString = LocalizationConstants.FeatureAuthentication.EmailLogin

    private enum Layout {
        static let topPadding: CGFloat = 34
        static let bottomPadding: CGFloat = 34
        static let leadingPadding: CGFloat = 24
        static let trailingPadding: CGFloat = 24

        static let resetTwoFATextSpacing: CGFloat = 2
        static let troubleLogInTextTopPadding: CGFloat = 1
        static let linkTextFontSize: CGFloat = 14
        static let textFieldBottomPadding: CGFloat = 20
    }

    private let context: CredentialsContext
    private let store: Store<CredentialsState, CredentialsAction>
    @ObservedObject private var viewStore: ViewStore<CredentialsState, CredentialsAction>

    private var twoFATitle: String {
        switch viewStore.twoFAState?.twoFAType {
        case nil, .standard, .email:
            return ""
        case .sms:
            return LocalizedString.TextFieldTitle.smsCode
        case .google:
            return LocalizedString.TextFieldTitle.authenticatorCode
        case .yubiKey, .yubikeyMtGox:
            return LocalizedString.TextFieldTitle.hardwareKeyCode
        }
    }

    private var twoFAErrorMessage: String {
        guard !viewStore.isAccountLocked else {
            return LocalizedString.TextFieldError.accountLocked
        }
        guard let twoFAState = viewStore.twoFAState,
              twoFAState.isTwoFACodeIncorrect
        else {
            return ""
        }
        switch twoFAState.twoFACodeIncorrectContext {
        case .incorrect:
            return String(
                format: LocalizedString.TextFieldError.incorrectTwoFACode,
                viewStore.twoFAState?.twoFACodeAttemptsLeft ?? 0
            )
        case .missingCode:
            return LocalizedString.TextFieldError.missingTwoFACode
        case .none:
            return ""
        }
    }

    @State private var isWalletIdentifierFirstResponder: Bool = false
    @State private var isPasswordFieldFirstResponder: Bool = false
    @State private var isTwoFAFieldFirstResponder: Bool = false
    @State private var isPasswordVisible: Bool = false
    @State private var isHardwareKeyVisible: Bool = false

    public init(context: CredentialsContext, store: Store<CredentialsState, CredentialsAction>) {
        self.context = context
        self.store = store
        viewStore = ViewStore(store)
    }

    // swiftlint:disable closure_body_length
    public var body: some View {
        VStack(alignment: .leading) {
            emailOrWalletIdentifierView()
                .padding(.bottom, Layout.textFieldBottomPadding)

            passwordField
                .accessibility(identifier: AccessibilityIdentifiers.CredentialsScreen.passwordGroup)

            Button(
                action: {
                    viewStore.send(.setTroubleLoggingInScreenVisible(true))
                },
                label: {
                    Text(LocalizedString.Link.troubleLogInLink)
                        .font(Font(weight: .medium, size: Layout.linkTextFontSize))
                        .foregroundColor(.buttonLinkText)
                }
            )
            .padding(.top, Layout.troubleLogInTextTopPadding)
            .accessibility(identifier: AccessibilityIdentifiers.CredentialsScreen.troubleLoggingInButton)

            if let state = viewStore.twoFAState, state.isTwoFACodeFieldVisible {
                twoFAField
                    .padding(.top, Layout.textFieldBottomPadding)
                    .padding(.bottom, Layout.troubleLogInTextTopPadding)
                    .accessibility(identifier: AccessibilityIdentifiers.CredentialsScreen.twoFAGroup)

                if let state = viewStore.twoFAState, state.isResendSMSButtonVisible {
                    Button(
                        action: {
                            viewStore.send(.walletPairing(.resendSMSCode))
                        },
                        label: {
                            Text(LocalizedString.Button.resendSMS)
                                .font(Font(weight: .medium, size: Layout.linkTextFontSize))
                                .foregroundColor(.buttonLinkText)
                        }
                    )
                    .accessibility(identifier: AccessibilityIdentifiers.CredentialsScreen.resendSMSButton)
                }

                if viewStore.twoFAState?.twoFAType == .yubiKey || viewStore.twoFAState?.twoFAType == .yubikeyMtGox {
                    Text(LocalizedString.TextFieldFootnote.hardwareKeyInstruction)
                        .textStyle(.subheading)
                }

                HStack(spacing: Layout.resetTwoFATextSpacing) {
                    Text(LocalizedString.TextFieldFootnote.lostTwoFACodePrompt)
                        .textStyle(.subheading)
                    Button(
                        action: {
                            guard let url = URL(string: Constants.HostURL.resetTwoFA) else { return }
                            UIApplication.shared.open(url)
                        },
                        label: {
                            Text(LocalizedString.Link.resetTwoFALink)
                                .font(Font(weight: .medium, size: Layout.linkTextFontSize))
                                .foregroundColor(.buttonLinkText)
                        }
                    )
                }
                .padding(.top, 0.5)
                .accessibility(identifier: AccessibilityIdentifiers.CredentialsScreen.resetTwoFAButton)
            }

            Spacer()

            PrimaryButton(
                title: LocalizedString.Button._continue,
                isLoading: viewStore.isLoading
            ) {
                viewStore.send(.continueButtonTapped)
            }
            .disabled(viewStore.isLoading || viewStore.walletPairingState.walletGuid.isEmpty)

            PrimaryNavigationLink(
                destination: IfLetStore(
                    store.scope(
                        state: \.seedPhraseState,
                        action: CredentialsAction.seedPhrase
                    ),
                    then: { store in
                        SeedPhraseView(store: store)
                    }
                ),
                isActive: viewStore.binding(
                    get: \.isTroubleLoggingInScreenVisible,
                    send: CredentialsAction.setTroubleLoggingInScreenVisible(_:)
                ),
                label: EmptyView.init
            )
        }
        .padding(
            EdgeInsets(
                top: Layout.topPadding,
                leading: Layout.leadingPadding,
                bottom: Layout.bottomPadding,
                trailing: Layout.trailingPadding
            )
        )
        .primaryNavigation(title: LocalizedString.navigationTitle) {
            Button {
                viewStore.send(.continueButtonTapped)
            } label: {
                Text(LocalizedString.Button.next)
                    .typography(.paragraph2)
                    .foregroundColor(
                        viewStore.walletPairingState.walletGuid.isEmpty ? .semantic.muted : .semantic.primary
                    )
            }
            .disabled(viewStore.walletPairingState.walletGuid.isEmpty)
            .accessibility(identifier: AccessibilityIdentifiers.CredentialsScreen.nextButton)
        }
        .onAppear {
            viewStore.send(.didAppear(context: context))
        }
        .onWillDisappear {
            viewStore.send(.onWillDisappear)
        }
        .alert(self.store.scope(state: \.credentialsFailureAlert), dismiss: .alert(.dismiss))
    }

    // MARK: - Private

    private func emailOrWalletIdentifierView() -> AnyView {
        switch context {
        case .walletInfo(let info):
            return AnyView(emailTextfield(info: info))
        case .walletIdentifier,
             .manualPairing:
            return AnyView(walletIdentifierTextfield())
        case .none:
            return AnyView(Divider().foregroundColor(.clear))
        }
    }

    private func emailTextfield(info: WalletInfo) -> some View {
        FormTextFieldGroup(
            text: .constant(viewStore.walletPairingState.emailAddress),
            isFirstResponder: .constant(false),
            isError: .constant(false),
            title: LocalizedString.TextFieldTitle.email,
            footnote: LocalizedString.TextFieldFootnote.wallet + viewStore.walletPairingState.walletGuid,
            isPrefilledAndDisabled: true
        )
        .accessibility(identifier: AccessibilityIdentifiers.CredentialsScreen.emailGuidGroup)
    }

    private func walletIdentifierTextfield() -> some View {
        FormTextFieldGroup(
            text: viewStore.binding(
                get: { $0.walletPairingState.walletGuid },
                send: { .didChangeWalletIdentifier($0) }
            ),
            isFirstResponder: $isWalletIdentifierFirstResponder,
            isError: viewStore.binding(
                get: \.isWalletIdentifierIncorrect,
                send: .none
            ),
            title: LocalizedString.TextFieldTitle.walletIdentifier,
            configuration: {
                $0.autocorrectionType = .no
                $0.autocapitalizationType = .none
                $0.textContentType = .username
                $0.returnKeyType = .next
            },
            onPaddingTapped: {
                self.isWalletIdentifierFirstResponder = true
                self.isPasswordFieldFirstResponder = false
                self.isTwoFAFieldFirstResponder = false
            },
            onReturnTapped: {
                self.isWalletIdentifierFirstResponder = false
                self.isPasswordFieldFirstResponder = true
                self.isTwoFAFieldFirstResponder = false
            }
        )
        .accessibility(identifier: AccessibilityIdentifiers.CredentialsScreen.guidGroup)
    }

    private var passwordField: some View {
        FormTextFieldGroup(
            text: viewStore.binding(
                get: \.passwordState.password,
                send: { .password(.didChangePassword($0)) }
            ),
            isFirstResponder: $isPasswordFieldFirstResponder,
            isError: viewStore.binding(
                get: { $0.passwordState.isPasswordIncorrect || $0.isAccountLocked },
                send: .none
            ),
            title: LocalizedString.TextFieldTitle.password,
            configuration: {
                $0.autocorrectionType = .no
                $0.autocapitalizationType = .none
                $0.isSecureTextEntry = !isPasswordVisible
                $0.textContentType = .password
            },
            errorMessage: viewStore.isAccountLocked ?
                LocalizedString.TextFieldError.accountLocked :
                LocalizedString.TextFieldError.incorrectPassword,
            onPaddingTapped: {
                self.isWalletIdentifierFirstResponder = false
                self.isPasswordFieldFirstResponder = true
                self.isTwoFAFieldFirstResponder = false
            },
            onReturnTapped: {
                self.isWalletIdentifierFirstResponder = false
                self.isPasswordFieldFirstResponder = false
                if let state = viewStore.twoFAState, state.isTwoFACodeFieldVisible {
                    self.isTwoFAFieldFirstResponder = true
                } else {
                    viewStore.send(.continueButtonTapped)
                }
            },
            trailingAccessoryView: {
                PasswordEyeSymbolButton(isPasswordVisible: $isPasswordVisible)
            }
        )
    }

    private var twoFAField: some View {
        FormTextFieldGroup(
            text: viewStore.binding(
                get: { $0.twoFAState?.twoFACode ?? "" },
                send: { .twoFA(.didChangeTwoFACode($0)) }
            ),
            isFirstResponder: $isTwoFAFieldFirstResponder,
            isError: viewStore.binding(
                get: { $0.twoFAState?.isTwoFACodeIncorrect ?? false || $0.isAccountLocked },
                send: .none
            ),
            title: twoFATitle,
            configuration: {
                $0.autocorrectionType = .no
                $0.autocapitalizationType = .none
                $0.textContentType = .oneTimeCode
                $0.isSecureTextEntry = !isHardwareKeyVisible &&
                    viewStore.twoFAState?.twoFAType == .yubiKey ||
                    viewStore.twoFAState?.twoFAType == .yubikeyMtGox
                $0.returnKeyType = .done
            },
            errorMessage: twoFAErrorMessage,
            onPaddingTapped: {
                self.isWalletIdentifierFirstResponder = false
                self.isPasswordFieldFirstResponder = false
                self.isTwoFAFieldFirstResponder = true
            },
            onReturnTapped: {
                self.isWalletIdentifierFirstResponder = false
                self.isPasswordFieldFirstResponder = false
                self.isTwoFAFieldFirstResponder = false
                viewStore.send(.continueButtonTapped)
            },
            trailingAccessoryView: {
                if viewStore.twoFAState?.twoFAType == .yubiKey ||
                    viewStore.twoFAState?.twoFAType == .yubikeyMtGox
                {
                    PasswordEyeSymbolButton(isPasswordVisible: $isHardwareKeyVisible)
                } else {
                    EmptyView()
                }
            }
        )
    }
}

#if DEBUG
struct PasswordLoginView_Previews: PreviewProvider {
    static var previews: some View {
        CredentialsView(
            context: .none,
            store: Store(
                initialState: .init(),
                reducer: credentialsReducer,
                environment: .init(
                    mainQueue: .main,
                    deviceVerificationService: NoOpDeviceVerificationService(),
                    errorRecorder: NoOpErrorRecorder(),
                    featureFlagsService: NoOpFeatureFlagsService(),
                    analyticsRecorder: NoOpAnalyticsRecorder(),
                    walletRecoveryService: .noop,
                    walletCreationService: .noop,
                    walletFetcherService: .noop,
                    accountRecoveryService: NoOpAccountRecoveryService()
                )
            )
        )
    }
}
#endif
