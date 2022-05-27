// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import ComposableArchitecture
import Localization
import NabuNetworkError
import SwiftUI

struct ErrorView: View {

    let title: String
    let description: String
    let retryTitle: String
    let cancelTitle: String

    let retryAction: (() -> Void)?
    let cancelAction: () -> Void

    init(
        title: String,
        description: String,
        retryTitle: String = LocalizationConstants
            .CardIssuing
            .Error
            .retry,
        cancelTitle: String = LocalizationConstants
            .CardIssuing
            .Error
            .cancelGoBack,
        retryAction: (() -> Void)? = nil,
        cancelAction: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.retryTitle = retryTitle
        self.cancelTitle = cancelTitle
        self.retryAction = retryAction
        self.cancelAction = cancelAction
    }

    var body: some View {
        VStack(spacing: Spacing.padding2) {
            ZStack(alignment: .topTrailing) {
                Icon
                    .creditcard
                    .accentColor(.WalletSemantic.primary)
                    .frame(width: 60, height: 60)
                ZStack {
                    Circle()
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                    Circle()
                        .foregroundColor(.WalletSemantic.error)
                        .frame(width: 22, height: 22)
                    Icon
                        .error
                        .frame(width: 12, height: 12)
                        .accentColor(.white)
                }
                .padding(.top, -4)
                .padding(.trailing, -8)
            }
            .padding(.top, Spacing.padding6)
            VStack(spacing: Spacing.padding1) {
                Text(title)
                    .typography(.title3)
                    .multilineTextAlignment(.center)
                Text(description)
                    .typography(.paragraph1)
                    .foregroundColor(.WalletSemantic.body)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.padding3)
            Spacer()
            if let retryAction = retryAction {
                PrimaryButton(
                    title: retryTitle
                ) {
                    retryAction()
                }
            }
            MinimalButton(
                title: cancelTitle
            ) {
                cancelAction()
            }
        }
        .padding(Spacing.padding3)
    }
}

#if DEBUG
struct Error_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(
            title: LocalizationConstants
                .CardIssuing
                .Errors
                .GenericProcessingError
                .title,
            description: LocalizationConstants
                .CardIssuing
                .Errors
                .GenericProcessingError
                .description,
            retryAction: {},
            cancelAction: {}
        )
    }
}
#endif

extension ErrorView {

    init(
        error: NabuNetworkError,
        cancelAction: @escaping () -> Void
    ) {
        self.init(
            title: error.displayTitle(
                fallback: LocalizationConstants.Errors.error
            ),
            description: error.displayDescription(
                fallback: LocalizationConstants.Errors.genericError
            ),
            cancelAction: cancelAction
        )
    }
}

extension NabuNetworkError {

    func displayTitle(fallback: String) -> String {
        guard case .nabuError(let error) = self else {
            return fallback
        }

        switch error.code {
        case .cardIssuingKycFailed:
            return LocalizationConstants
                .CardIssuing
                .Errors
                .KycFailed
                .title
        case .cardIssuingSsnInvalid:
            return LocalizationConstants
                .CardIssuing
                .Errors
                .InvalidSsn
                .title
        case .tierTooLow:
            return LocalizationConstants
                .CardIssuing
                .Errors
                .TierTooLow
                .title
        case .countryNotEligible:
            return LocalizationConstants
                .CardIssuing
                .Errors
                .CountryNotEligible
                .title
        case .stateNotEligible:
            return LocalizationConstants
                .CardIssuing
                .Errors
                .StateNotEligible
                .title
        case .notFound:
            return LocalizationConstants
                .CardIssuing
                .Errors
                .NotFound
                .title
        default:
            return LocalizationConstants
                .Errors
                .error
        }
    }

    func displayDescription(fallback: String) -> String {
        guard case .nabuError(let error) = self else {
            return fallback
        }

        switch error.code {
        case .cardIssuingKycFailed:
            return LocalizationConstants
                .CardIssuing
                .Errors
                .KycFailed
                .description
        case .cardIssuingSsnInvalid:
            return LocalizationConstants
                .CardIssuing
                .Errors
                .InvalidSsn
                .description
        case .tierTooLow:
            return LocalizationConstants
                .CardIssuing
                .Errors
                .TierTooLow
                .description
        case .countryNotEligible:
            return LocalizationConstants
                .CardIssuing
                .Errors
                .CountryNotEligible
                .description
        case .stateNotEligible:
            return LocalizationConstants
                .CardIssuing
                .Errors
                .StateNotEligible
                .description
        case .notFound:
            return LocalizationConstants
                .CardIssuing
                .Errors
                .NotFound
                .description
        default:
            return fallback
        }
    }

    var retryTitle: String {
        let retry = LocalizationConstants
            .CardIssuing
            .Error
            .retry

        guard case .nabuError(let error) = self else {
            return retry
        }

        switch error.code {
        case .stateNotEligible:
            return LocalizationConstants
                .CardIssuing
                .Errors
                .StateNotEligible
                .seeList
        case .countryNotEligible:
            return LocalizationConstants
                .CardIssuing
                .Errors
                .StateNotEligible
                .seeList
        default:
            return retry
        }
    }
}
