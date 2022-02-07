// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import BlockchainComponentLibrary
import ComposableArchitecture
import FeatureAuthenticationDomain
import Localization
import SwiftUI
import ToolKit
import UIComponentsKit

struct ResetAccountFailureView: View {

    private typealias LocalizedString = LocalizationConstants.FeatureAuthentication.ResetAccountWarning

    private enum Layout {
        static let bottomPadding: CGFloat = 34
        static let leadingPadding: CGFloat = 24
        static let trailingPadding: CGFloat = 24

        static let imageSideLength: CGFloat = 72
        static let imageBottomPadding: CGFloat = 16
        static let descriptionFontSize: CGFloat = 16
        static let descriptionLineSpacing: CGFloat = 4
        static let callOutMessageBottomPadding: CGFloat = 16
        static let callOutMessageFontSize: CGFloat = 12
        static let callOutMessageCornerRadius: CGFloat = 8
    }

    private let store: Store<ResetAccountFailureState, ResetAccountFailureAction>
    @ObservedObject private var viewStore: ViewStore<ResetAccountFailureState, ResetAccountFailureAction>

    init(store: Store<ResetAccountFailureState, ResetAccountFailureAction>) {
        self.store = store
        viewStore = ViewStore(store)
    }

    var body: some View {
        VStack {
            VStack {
                Spacer()
                Image.CircleIcon.warning
                    .frame(width: Layout.imageSideLength, height: Layout.imageSideLength)
                    .padding(.bottom, Layout.imageBottomPadding)
                    .accessibility(
                        identifier: AccessibilityIdentifiers.ResetAccountFailureScreen.resetAccountFailureImage
                    )

                Text(LocalizedString.Title.recoveryFailed)
                    .textStyle(.title)
                    .accessibility(
                        identifier: AccessibilityIdentifiers.ResetAccountFailureScreen.resetAccountFailureTitleText
                    )
                    .multilineTextAlignment(.center)

                Text(LocalizedString.Message.recoveryFailed)
                    .font(Font(weight: .medium, size: Layout.descriptionFontSize))
                    .foregroundColor(.textSubheading)
                    .lineSpacing(Layout.descriptionLineSpacing)
                    .multilineTextAlignment(.center)
                    .accessibility(
                        identifier: AccessibilityIdentifiers.ResetAccountFailureScreen.resetAccountFailureMessageText
                    )
                Spacer()

                recoveryFailedCallOutGroup
                    .padding(.bottom, Layout.callOutMessageBottomPadding)
                    .accessibility(
                        identifier: AccessibilityIdentifiers.ResetAccountFailureScreen.resetAccountFailureCallOutGroup
                    )

                PrimaryButton(title: LocalizedString.Button.contactSupport) {
                    viewStore.send(.open(urlContent: .support))
                }
                .accessibility(
                    identifier: AccessibilityIdentifiers.ResetAccountFailureScreen.contactSupportButton
                )
            }
            .padding(
                EdgeInsets(
                    top: 0,
                    leading: Layout.leadingPadding,
                    bottom: Layout.bottomPadding,
                    trailing: Layout.trailingPadding
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .hideBackButtonTitle()
        }
    }

    private var recoveryFailedCallOutGroup: some View {
        HStack {
            Text(LocalizedString.recoveryFailureCallout + " ")
                .font(Font(weight: .medium, size: Layout.callOutMessageFontSize))
                .foregroundColor(.textSubheading) +
                Text(LocalizedString.Button.learnMore)
                .font(Font(weight: .medium, size: Layout.callOutMessageFontSize))
                .foregroundColor(Color.buttonPrimaryBackground)
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        .background(
            RoundedRectangle(cornerRadius: Layout.callOutMessageCornerRadius)
                .fill(Color.textCallOutBackground)
        )
        .onTapGesture {
            viewStore.send(.open(urlContent: .learnMore))
        }
    }
}

#if DEBUG
struct ResetAccountFailureView_Previews: PreviewProvider {
    static var previews: some View {
        ResetAccountFailureView(
            store: .init(
                initialState: .init(),
                reducer: resetAccountFailureReducer,
                environment: ResetAccountFailureEnvironment()
            )
        )
    }
}
#endif
