// Copyright © Blockchain Luxembourg S.A. All rights reserved.

// swiftlint:disable all

import Foundation

extension LocalizationConstants {
    public enum FeatureCryptoDomain {}
}

extension LocalizationConstants.FeatureCryptoDomain {

    // MARK: - Claim Introduction Screen

    public enum ClaimIntroduction {
        public static let title = NSLocalizedString(
            "Claim Your Domain",
            comment: "Claim Introduction view navigation title"
        )
        public enum Header {
            public static let title = NSLocalizedString(
                "How It Works",
                comment: "Claim Introduction header title"
            )
            public static let description = NSLocalizedString(
                "Claiming your crypto domain is easy. Follow the steps below to claim your free domain* through Unstoppable Domains.",
                comment: "Claim Introduction view header description"
            )
        }

        public enum ListView {
            public enum ChooseDomain {
                public static let title = NSLocalizedString(
                    "Choose Your Domain",
                    comment: "Claim Introduction choose domain row title"
                )
                public static let description = NSLocalizedString(
                    "Select a domain and mint it to get started.",
                    comment: "Claim Introduction choose domain row description"
                )
            }

            public enum ClaimDomain {
                public static let title = NSLocalizedString(
                    "Claim Your Domain",
                    comment: "Claim Introduction chaim domain row title"
                )
                public static let description = NSLocalizedString(
                    "Claim your free domain provided by Unstoppable Domains.",
                    comment: "Claim Introduction chaim domain row description"
                )
            }

            public enum ReceiveCrypto {
                public static let title = NSLocalizedString(
                    "Receive Crypto",
                    comment: "Claim Introduction receive crypto row title"
                )
                public static let description = NSLocalizedString(
                    "Share your domain rather than your wallet address to receive crypto.",
                    comment: "Claim Introduction receive crypto row description"
                )
            }
        }

        public static let promptButton = NSLocalizedString(
            "What’s a Crypto Domain?",
            comment: "What’s a Crypto Domain? prompt button text"
        )
        public static let instruction = NSLocalizedString(
            "*Free domains must be a minimum of 7 characters long and not a protected domain. (e.g. nike.blockchain)",
            comment: "Claim instruction"
        )
        public static let goButton = NSLocalizedString(
            "Let's Go",
            comment: "Let's go button text"
        )
    }

    // MARK: - Claim Benefits Screen

    public enum ClaimBenefits {
        public enum Header {
            public static let title = NSLocalizedString(
                "What’s a Crypto Domain?",
                comment: "What's a crypto domain header title"
            )
            public static let description = NSLocalizedString(
                "Crypto domains are like a universal username for the world of crypto.",
                comment: "What's a crypto domain header description"
            )
        }

        public enum BenefitsList {
            public enum SimplifyTransaction {
                public static let title = NSLocalizedString(
                    "Simplify Crypto Transactions",
                    comment: "Simplify Transaction benefit title"
                )
                public static let description = NSLocalizedString(
                    "Replace all your complicated wallet addresses your domain name.",
                    comment: "Simplify Transaction benefit description"
                )
            }

            public enum MultiNetwork {
                public static let title = NSLocalizedString(
                    "Multiple Coins and Networks",
                    comment: "MultiNetwork benefit title"
                )
                public static let description = NSLocalizedString(
                    "Receive 275+ coins across multiple blockchain networks with your domain.",
                    comment: "MultiNetwork benefit description"
                )
            }

            public enum Ownership {
                public static let title = NSLocalizedString(
                    "Full Ownership",
                    comment: "Ownership benefit title"
                )
                public static let description = NSLocalizedString(
                    "Unlike traditional domains, fully own and control your domain. Claim it once, own it for life!",
                    comment: "Ownership benefit description"
                )
            }

            public enum MuchMore {
                public static let title = NSLocalizedString(
                    "And Much More",
                    comment: "Much more benefit title"
                )
                public static let description = NSLocalizedString(
                    "Use your domain to login to web3 apps, create and host websites, and showcase your NFT galleries.",
                    comment: "Much more beneift description"
                )
            }
        }

        public static let claimButton = NSLocalizedString(
            "Claim Domain",
            comment: "Claim domain CTA button"
        )
    }

    // MARK: - Search Domain Screen

    public enum SearchDomain {
        public static let title = NSLocalizedString(
            "Search Domains",
            comment: "Search Domains list view navigation title"
        )
        public enum Description {
            public static let title = NSLocalizedString(
                "What's a free domain?",
                comment: "Search Domains list view description title"
            )
            public static let body = NSLocalizedString(
                "Free domains must be a minimum of 7 characters long and not a special domain like nike.blockchain.",
                comment: "Search Domains list view description body"
            )
        }

        public enum ListView {
            public static let freeDomain = NSLocalizedString(
                "Free domain",
                comment: "Search Domains list view free domain status"
            )
            public static let premiumDomain = NSLocalizedString(
                "Premium domain",
                comment: "Search Domains list view premium domain status"
            )
            public static let free = NSLocalizedString(
                "Free",
                comment: "Search Domains list view availability status (free)"
            )
            public static let unavailable = NSLocalizedString(
                "Unavailable",
                comment: "Search Domains list view availability status (unavailable)"
            )
        }
    }
}
