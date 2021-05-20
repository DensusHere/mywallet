// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SharedPackagesKit
import SwiftUI
import UIComponentsKit

/// Entry point to the Email Verification flow
struct EmailVerificationView: View {

    let store: Store<EmailVerificationState, EmailVerificationAction>
    let viewStore: ViewStore<EmailVerificationState, EmailVerificationAction>

    init(store: Store<EmailVerificationState, EmailVerificationAction>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    var body: some View {
        NavigationView {
            VStack {
                // Programmatic Navigation Stack
                // `EmptyView`s are set as source to hide the links since individual EV subviews don't know about destinations
                NavigationLink(
                    destination: EmailVerificationHelpRoutingView(
                        canShowEditAddressView: viewStore.flowStep == .editEmailAddress,
                        store: store
                    ),
                    isActive: .constant(viewStore.flowStep == .emailVerificationHelp || viewStore.flowStep == .editEmailAddress),
                    label: EmptyView.init
                )

                // Root View when loading Email Verification Status
                if viewStore.flowStep == .loadingVerificationState || viewStore.flowStep == .verificationCheckFailed {
                    ActivityIndicatorView()
                        .accessibility(identifier: "KYC.EmailVerification.loading.spinner")
                        .alert(
                            store.scope(state: \.emailVerificationFailedAlert),
                            dismiss: .dismissEmailVerificationFailedAlert
                        )
                } else if viewStore.flowStep == .emailVerifiedPrompt {
                    // Final step of the flow
                    EmailVerifiedView(
                        store: store.scope(
                            state: \.emailVerified,
                            action: EmailVerificationAction.emailVerified
                        )
                    )
                    .navigationBarHidden(true)
                } else {
                    // Default Root View
                    VerifyEmailView(
                        store: store.scope(
                            state: \.verifyEmail,
                            action: EmailVerificationAction.verifyEmail
                        )
                    )
                    .navigationBarHidden(true)
                }
            }
            .onAppEnteredForeground {
                viewStore.send(.didEnterForeground)
            }
            .background(Color.viewPrimaryBackground)
            .accessibility(identifier: "KYC.EmailVerification.container")
        }
    }
}

struct EmailVerificationHelpRoutingView: View {

    let canShowEditAddressView: Bool
    let store: Store<EmailVerificationState, EmailVerificationAction>

    var body: some View {
        VStack {
            NavigationLink(
                destination: (
                    EditEmailView(
                        store: store.scope(
                            state: \.editEmailAddress,
                            action: EmailVerificationAction.editEmailAddress
                        )
                    )
                    .navigationBarBackButtonHidden(true)
                ),
                isActive: .constant(canShowEditAddressView),
                label: EmptyView.init
            )
            EmailVerificationHelpView(
                store: store.scope(
                    state: \.emailVerificationHelp,
                    action: EmailVerificationAction.emailVerificationHelp
                )
            )
            .navigationBarBackButtonHidden(true)
        }
    }
}

#if DEBUG
struct EmailVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        EmailVerificationView(
            store: .init(
                initialState: .init(emailAddress: "test@example.com"),
                reducer: emailVerificationReducer,
                environment: EmailVerificationEnvironment(
                    emailVerificationService: NoOpEmailVerificationService(),
                    flowCompletionCallback: nil,
                    mainQueue: .main,
                    openMailApp: { Effect(value: true) }
                )
            )
        )
    }
}
#endif