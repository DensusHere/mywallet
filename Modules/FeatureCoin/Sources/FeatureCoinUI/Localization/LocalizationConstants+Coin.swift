// Copyright © Blockchain Luxembourg S.A. All rights reserved.

// swiftlint:disable line_length

import Localization

extension LocalizationConstants {
    enum Coin {
        enum Label {
            enum Title {
                static let currentCryptoPrice = NSLocalizedString(
                    "Current %@ Price",
                    comment: "Coin View: Current crypto price label title"
                )
                static let aboutCrypto = NSLocalizedString(
                    "About %@",
                    comment: "Coin View: About crypto label title"
                )

                static let notTradable = NSLocalizedString(
                    "%@ (%@) is not tradable",
                    comment: "Coin View: Not tradable crypto label title"
                )

                static let notTradableMessage = NSLocalizedString(
                    "%@ (%@) is currently unavailable to trade.",
                    comment: "Coin View: Not tradable crypto label message"
                )

                static let addToWatchListInfo = NSLocalizedString(
                    "Add to your watchlist to be notified when %@ is available to trade.",
                    comment: "Coin View: add crypto to watchlist label title"
                )
            }
        }

        enum Link {
            enum Title {
                static let visitWebsite = NSLocalizedString(
                    "Visit Website ->",
                    comment: "Coin View: Visit website link title"
                )
            }
        }

        enum Button {
            enum Title {
                static let buy = NSLocalizedString(
                    "Buy",
                    comment: "Coin View: Buy CTA"
                )
                static let sell = NSLocalizedString(
                    "Sell",
                    comment: "Coin View: Sell CTA"
                )
                static let send = NSLocalizedString(
                    "Send",
                    comment: "Coin View: Send CTA"
                )
                static let receive = NSLocalizedString(
                    "Receive",
                    comment: "Coin View: Receive CTA"
                )
                static let readMore = NSLocalizedString(
                    "Read More",
                    comment: "Coin View: Read More and expand on the Asset Description"
                )
            }
        }

        enum Accounts {

            enum Error {
                static let title = NSLocalizedString(
                    "Oops! There was a problem loading account data",
                    comment: "Coin View: Error loading account data title"
                )
                static let message = NSLocalizedString(
                    "We are experiencing a service issue that may affect displayed balances. Don't worry, your funds are safe.",
                    comment: "Coin View: Error loading account data message"
                )
            }

            static let totalBalance = NSLocalizedString(
                "Your Total %@",
                comment: "Coin View: Total balance title, interpolating the cryptocurrency code. e.g. BTC"
            )

            static let sectionTitle = NSLocalizedString(
                "Wallets & Accounts",
                comment: "Coin View: accounts section header title"
            )

            static let tradingAccountTitle = NSLocalizedString(
                "Trading Account",
                comment: "Coin View: trading account title"
            )

            static let tradingAccountSubtitle = NSLocalizedString(
                "Buy and Sell Bitcoin",
                comment: "Coin View: trading account subtitle"
            )

            static let rewardsAccountTitle = NSLocalizedString(
                "Rewards Account",
                comment: "Coin View: rewards account title"
            )

            static let rewardsAccountSubtitle = NSLocalizedString(
                "Earn %.1f%% APY",
                comment: "Coin View: rewards account subtitle"
            )

            static let exchangeAccountTitle = NSLocalizedString(
                "Exchange Account",
                comment: "Coin View: exchange account title"
            )

            static let exchangeAccountSubtitle = NSLocalizedString(
                "Connect to the Exchange",
                comment: "Coin View: exchange account subtitle"
            )
        }

        enum Account {

            static let privateKey = (
                subtitle: NSLocalizedString(
                    "Non-custodial",
                    comment: "Coin View: Non-custodial account subtitle"
                ), ()
            )

            static let trading = (
                subtitle: NSLocalizedString(
                    "Custodial",
                    comment: "Coin View: Custodial account subtitle"
                ), ()
            )

            static let interest = (
                subtitle: NSLocalizedString(
                    "Earning %.1f%%",
                    comment: "Coin View: Rewards account subtitle"
                ), ()
            )

            static let exchange = (
                subtitle: NSLocalizedString(
                    "Pro Trading",
                    comment: "Coin View: Exchange account subtitle"
                ), ()
            )

            enum Explainer {

                static let privateKey = (
                    title: NSLocalizedString(
                        "Private Key Wallet",
                        comment: "Coin View: Private Key Wallet Explainer title"
                    ),
                    body: NSLocalizedString(
                        "Your Private Key Wallet means your funds are owned and controlled by you and you alone. Blockchain.com cannot see or manage your balances in this wallet.",
                        comment: "Coin View: Private Key Wallet Explainer body"
                    ),
                    action: NSLocalizedString(
                        "I understand",
                        comment: "Coin View: Private Key Wallet Explainer action"
                    )
                )

                static let trading = (
                    title: NSLocalizedString(
                        "Trading Account",
                        comment: "Coin View: Trading Account Explainer title"
                    ),
                    body: NSLocalizedString(
                        "Your Trading Account is a custodial account hosted by Blockchain.com. Your trading account allows you to trade with cheaper fees and buy and sell crypto in seconds.",
                        comment: "Coin View: Trading Account Explainer body"
                    ),
                    action: NSLocalizedString(
                        "I understand",
                        comment: "Coin View: Trading Account Explainer action"
                    )
                )

                static let rewards = (
                    title: NSLocalizedString(
                        "Rewards Account",
                        comment: "Coin View:Rewards Account Explainer title"
                    ),
                    body: NSLocalizedString(
                        "Your Rewards Account allows you to earn rewards on your crypto.",
                        comment: "Coin View: Rewards Account Explainer body"
                    ),
                    action: NSLocalizedString(
                        "I understand",
                        comment: "Coin View: Rewards Account Explainer action"
                    )
                )

                static let exchange = (
                    title: NSLocalizedString(
                        "Connect to Exchange",
                        comment: "Coin View: Exchange Explainer title"
                    ),
                    body: NSLocalizedString(
                        "Connect your Exchange and Wallet accounts to view your balances and transfer funds.",
                        comment: "Coin View: Exchange Explainer body"
                    ),
                    action: NSLocalizedString(
                        "Connect",
                        comment: "Coin View: Exchange Explainer action"
                    )
                )
            }
        }

        enum Graph {

            static let price = NSLocalizedString(
                "Price",
                comment: "Coin View Graph: graph title showing price"
            )

            static let currentPrice = NSLocalizedString(
                "Current Price",
                comment: "Coin View Graph: graph title showing current price"
            )

            enum Error {
                static let title = NSLocalizedString(
                    "Oops! Something went wrong!",
                    comment: "Coin View Graph: Error title"
                )
                static let description = NSLocalizedString(
                    "There seems to be a problem fetching the chart data, please try again",
                    comment: "Coin View Graph: Error description"
                )
                static let retry = NSLocalizedString(
                    "Retry",
                    comment: "Coin View Graph: Retry on failure CTA"
                )
            }
        }
    }
}
