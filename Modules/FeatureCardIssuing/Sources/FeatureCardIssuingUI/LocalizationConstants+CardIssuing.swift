// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import FeatureCardIssuingDomain
import Foundation
import Localization

extension LocalizationConstants {
    public enum CardIssuing {
        enum CardType {
            enum Virtual {
                static let title = NSLocalizedString(
                    "Virtual",
                    comment: "Card Issuing: Type Virtual title"
                )

                static let description = NSLocalizedString(
                    "Our digital only card, use instantly for online payments.",
                    comment: "Card Issuing: Type Virtual description"
                )
            }
        }

        enum CardStatus {
            static let initiated = NSLocalizedString(
                "Initiated",
                comment: "Card Issuing: Card Status Initiated"
            )
            static let created = NSLocalizedString(
                "Created",
                comment: "Card Issuing: Card Status Created"
            )
            static let active = NSLocalizedString(
                "Ready to use",
                comment: "Card Issuing: Card Status Active"
            )
            static let terminated = NSLocalizedString(
                "Terminated",
                comment: "Card Issuing: Card Status Terminated"
            )
            static let suspended = NSLocalizedString(
                "Locked",
                comment: "Card Issuing: Card Status Suspended"
            )
            static let unsupported = NSLocalizedString(
                "Unsupported",
                comment: "Card Issuing: Card Status Unsupported"
            )
            static let unactivated = NSLocalizedString(
                "Unactivated",
                comment: "Card Issuing: Card Status Unactivated"
            )
            static let limited = NSLocalizedString(
                "Limited",
                comment: "Card Issuing: Card Status Limited"
            )
            static let locked = NSLocalizedString(
                "Locked",
                comment: "Card Issuing: Card State Locked"
            )
        }

        enum Navigation {
            static let title = NSLocalizedString(
                "Blockchain Card",
                comment: "Card Issuing: Navigation title"
            )
        }

        enum Error {
            static let retry = NSLocalizedString(
                "Retry",
                comment: "Card Issuing: Card Creation Error Retry Button"
            )

            static let cancelGoBack = NSLocalizedString(
                "Cancel & Go Back",
                comment: "Card Issuing: Card Creation Error Cancel & Go Back Button"
            )
        }
    }
}

extension Card.Status {

    var localizedString: String {
        let constants = LocalizationConstants.CardIssuing.CardStatus.self
        switch self {
        case .initiated:
            return constants.initiated
        case .created:
            return constants.created
        case .active:
            return constants.active
        case .terminated:
            return constants.terminated
        case .suspended:
            return constants.suspended
        case .unsupported:
            return constants.unsupported
        case .unactivated:
            return constants.unactivated
        case .limited:
            return constants.limited
        case .locked:
            return constants.locked
        }
    }
}

extension LocalizationConstants.CardIssuing {

    enum Errors {

        enum TierTooLow {

            static let title = NSLocalizedString(
                "Account not yet verified",
                comment: "Card Issuing Error: Title Tier Too Low"
            )

            static let description = NSLocalizedString(
                "Your customer details are pending verification or invalid. Please try again later.",
                comment: "Card Issuing Error: Description Tier Too Low"
            )
        }

        enum KycFailed {

            static let title = NSLocalizedString(
                "Unable to validate customer details",
                comment: "Card Issuing Error: Title KYC Failed"
            )

            static let description = NSLocalizedString(
                """
                The card issuer was unable to validate your customer details. \
                Please confirm that your details are correct and try again.
                """,
                comment: "Card Issuing Error: Description KYC Failed"
            )
        }

        enum CountryNotEligible {

            static let title = NSLocalizedString(
                "Service not available in your country",
                comment: "Card Issuing Error: Title Country Not Eligible"
            )

            static let description = NSLocalizedString(
                "Blockchain.com services are not yet available in your country.",
                comment: "Card Issuing Error: Description Country Not Eligible"
            )

            static let seeList = NSLocalizedString(
                "See eligible countries",
                comment: "Card Issuing Error: See eligible countries"
            )
        }

        enum StateNotEligible {

            static let title = NSLocalizedString(
                "Service not available in your state",
                comment: "Card Issuing Error: Title State Not Eligible"
            )

            static let description = NSLocalizedString(
                "Blockchain.com services are not yet available in your state.",
                comment: "Card Issuing Error: Description State Not Eligible"
            )

            static let seeList = NSLocalizedString(
                "See eligible states",
                comment: "Card Issuing Error: See eligible states"
            )
        }

        enum InvalidSsn {

            static let title = NSLocalizedString(
                "Invalid social security number",
                comment: "Card Issuing Error: Title Invalid SSN"
            )

            static let description = NSLocalizedString(
                "The social security number you provided is not valid. Please provide a valid one to continue.",
                comment: "Card Issuing Error: Description Invalid SSN"
            )
        }

        enum NotFound {

            static let title = NSLocalizedString(
                "Card not found",
                comment: "Card Issuing Error: Title Not Found"
            )

            static let description = NSLocalizedString(
                "We could not find the selected card. Please try again later or contact support.",
                comment: "Card Issuing Error: Description Not Found"
            )
        }

        enum GenericProcessingError {

            static let title = NSLocalizedString(
                "Failed To Create Your Card",
                comment: "Card Issuing: Card Creation Failed"
            )

            static let description = NSLocalizedString(
                """
                Sometimes this can happen when the systems are bogged down. \
                You can try again by clicking `Retry` below or come back again in a bit.
                """,
                comment: "Card Issuing: Card Creation Error message"
            )
        }
    }
}
