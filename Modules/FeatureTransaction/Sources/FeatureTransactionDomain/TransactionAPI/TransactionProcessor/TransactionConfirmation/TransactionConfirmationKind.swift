// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

public enum TransactionConfirmationKind: Equatable {
    case description
    case agreementInterestTandC
    case agreementInterestTransfer
    case readOnly
    case memo
    case largeTransactionWarning
    case feeSelection
    case errorNotice
    case invoiceCountdown
    case networkFee
    case quoteCountdown
}
