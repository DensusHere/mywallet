import Localization

typealias L10n = LocalizationConstants.CustodialOnboarding

extension LocalizationConstants {
    enum CustodialOnboarding {}
}

extension LocalizationConstants.CustodialOnboarding {

    static let completeYourProfile = NSLocalizedString("Complete your profile", comment: "Complete your profile")
    static let tradeCryptoToday = NSLocalizedString("Trade crypto today", comment: "Trade crypto today")
    static let verifyYourEmail = NSLocalizedString("Verify your email", comment: "Verify your email")
    static let completeIn30Seconds = NSLocalizedString("Complete in around 30 seconds", comment: "Complete in around 30 seconds")
    static let verifyYourIdentity = NSLocalizedString("Verify your identity", comment: "Verify your identity")
    static let completeIn2Minutes = NSLocalizedString("Complete in around 2 minutes", comment: "Complete in around 2 minutes")
    static let buyCrypto = NSLocalizedString("Buy crypto", comment: "Buy crypto")
    static let completeIn10Seconds = NSLocalizedString("Complete in around 10 seconds", comment: "Complete in around 10 seconds")

    static let beforeYouContinue = NSLocalizedString("Before you continue", comment: "Before you continue")
    static let startTradingCrypto = NSLocalizedString("To start trading crypto, we first need to verify your identity.", comment: "To start trading crypto, we first need to verify your identity.")
    static let verifyMyIdentity = NSLocalizedString("Verify my identity", comment: "Verify my identity")

    static let youDontHaveAnyBalance = NSLocalizedString("You don’t have any balance", comment: "You don’t have any balance")
    static let fundYourAccount = NSLocalizedString("Fund your account to start buying crypto", comment: "Fund your account to start buying crypto")
    static let deposit = NSLocalizedString("Deposit %@", comment: "Deposit %@")


    static let weCouldNotVerify = NSLocalizedString("We couldn't verify your identity", comment: "We couldn't verify your identity")
    static let unableToVerifyGoToDeFi = NSLocalizedString("It seems we're unable to verify your identity.\n\nHowever, you can still use our DeFi Wallet.", comment: "It seems we're unable to verify your identity.\n\nHowever, you can still use our DeFi Wallet.")
    static let goToDeFi = NSLocalizedString("Go to DeFi Wallet", comment: "Go to DeFi Wallet")

    static let completed = NSLocalizedString("Completed", comment: "Completed")
    static let inReview = NSLocalizedString("In review", comment: "In review")

    static let applicationSubmitted = NSLocalizedString("Application submitted", comment: "Application submitted")
    static let successfullyReceivedInformation = NSLocalizedString("We've successfully received your information.\n\nWe're experiencing high volumes of applications, and we'll notify you of the status of your application via email.", comment: "KYC Pending message")
    static let successfullyReceivedInformationCountdown = NSLocalizedString("We've successfully received your information and it's being reviewed.\n\nThis could take up to **60 seconds**.\nWe'll notify you via email about the status of your application.", comment: "KYC Pending message")
    static let cta = NSLocalizedString("Go to my Account", comment: "KYC Pending: CTA")
}
