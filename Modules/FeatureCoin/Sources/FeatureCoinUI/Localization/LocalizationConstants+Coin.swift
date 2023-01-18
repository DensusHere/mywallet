// Copyright © Blockchain Luxembourg S.A. All rights reserved.

// swiftlint:disable line_length

import Localization

extension LocalizationConstants {
    enum Coin {
        enum Header {
            static let walletsAndAccounts = NSLocalizedString("Wallets & Accounts", comment: "Wallets & Accounts")
        }

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
                static let swap = NSLocalizedString(
                    "Swap",
                    comment: "Coin View: Swap CTA"
                )
                static let readMore = NSLocalizedString(
                    "Read More",
                    comment: "Coin View: Read More and expand on the Asset Description"
                )
            }
        }

        enum RecurringBuy {
            enum Header {
                static let recurringBuys = NSLocalizedString("Recurring Buys", comment: "Recurring Buys")
            }

            enum LearnMore {
                static let title = NSLocalizedString("Don't know when to buy?", comment: "Coin view: Learn more card title")
                static let description = NSLocalizedString("Timing the market is hard, which is why many investors use Dollar Cost Averaging.", comment: "Coin view: Learn more card description")
                static let action = NSLocalizedString("Learn More", comment: "Coin view: button")
            }

            enum Row {
                static let frequency = NSLocalizedString("Next Buy: ", comment: "Coin view: describing when the next buy will occur")
            }

            enum Summary {
                public static let title = NSLocalizedString("Recurring Buy", comment: "Recurring Buy")
                public static let amount = NSLocalizedString("Amount", comment: "Amount")
                public static let crypto = NSLocalizedString("Crypto", comment: "Crypto")
                public static let paymentMethod = NSLocalizedString("Payment Method", comment: "Payment Method")
                public static let frequency = NSLocalizedString("Frequency", comment: "Frequency")
                public static let nextBuy = NSLocalizedString("Next Buy", comment: "Next Buy")
                public static let remove = NSLocalizedString("Remove", comment: "Remove")

                enum Removal {
                    public static let title = NSLocalizedString("Are you sure you want to remove this recurring buy?", comment: "Removal modal: title")
                    public static let remove = NSLocalizedString("Remove", comment: "Remove")
                    public static let keep = NSLocalizedString("Keep", comment: "Keep")
                }
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

            static let activeRewardsAccountTitle = NSLocalizedString(
                "Active Rewards Account",
                comment: "Coin View: rewards account title"
            )

            static let activeRewardsAccountSubtitle = NSLocalizedString(
                "Earn %.1f%% APY",
                comment: "Coin View: rewards account subtitle"
            )

            static let stakingAccountTitle = NSLocalizedString(
                "Staking Account",
                comment: "Coin View: rewards account title"
            )

            static let stakingAccountSubtitle = NSLocalizedString(
                "Earn %.1f%%",
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

            static let active = (
                subtitle: NSLocalizedString(
                    "Earning up to %.1f%%",
                    comment: "Coin View: Active Rewards account subtitle"
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
                    title: NonLocalizedConstants.defiWalletTitle,
                    body: NSLocalizedString(
                        "Your %@ means your funds are owned and controlled by you and you alone. Blockchain.com cannot see or manage your balances in this wallet.",
                        comment: "Coin View: DeFi Wallet Explainer body"
                    ),
                    action: NSLocalizedString(
                        "I understand",
                        comment: "Coin View: DeFi Wallet Explainer action"
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

                static let staking = (
                    title: NSLocalizedString(
                        "Staking Account",
                        comment: "Coin View:Staking Account Explainer title"
                    ),
                    body: NSLocalizedString(
                        "Your Staking Account allows you to earn rewards on your crypto.",
                        comment: "Coin View: Staking Account Explainer body"
                    ),
                    action: NSLocalizedString(
                        "I understand",
                        comment: "Coin View: Rewards Account Explainer action"
                    )
                )

                static let active = (
                    title: NSLocalizedString(
                        "Active Rewards Account",
                        comment: "Coin View: Active Rewards Account Explainer title"
                    ),
                    body: NSLocalizedString(
                        "Your Active Rewards Account allows you to earn by forecasting the price of crypto.",
                        comment: "Coin View: Active Rewards Account Explainer body"
                    ),
                    action: NSLocalizedString(
                        "I understand",
                        comment: "Coin View: Rewards Account Explainer action"
                    )
                )
            }

            enum ComingSoon {
                static let title = NSLocalizedString(
                    "Coming soon to mobile",
                    comment: "Coming soon to mobile title"
                )

                static let subtitle = NSLocalizedString(
                    "In the meantime, you can manage your %@ using our web app.",
                    comment: "In the meantime, you can manage your [account name] using our web app."
                )

                static let learnMore = NSLocalizedString(
                    "Learn More",
                    comment: "Learn More"
                )

                static let goToWebApp = NSLocalizedString(
                    "Go to Web App",
                    comment: "Go to Web App"
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
