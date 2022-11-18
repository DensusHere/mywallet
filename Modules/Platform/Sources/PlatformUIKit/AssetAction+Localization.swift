// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization
import PlatformKit

extension AssetAction {

    private typealias LocalizationIds = LocalizationConstants.Transaction

    public var name: String {
        switch self {
        case .buy:
            return LocalizationIds.buy
        case .viewActivity:
            return LocalizationIds.viewActivity
        case .linkToDebitCard:
            return LocalizationIds.linkToDebitCard
        case .interestTransfer:
            return LocalizationIds.transfer
        case .deposit, .stakingDeposit:
            return LocalizationIds.deposit
        case .sell:
            return LocalizationIds.sell
        case .send:
            return LocalizationIds.send
        case .sign:
            fatalError("Impossible.")
        case .receive:
            return LocalizationIds.receive
        case .swap:
            return LocalizationIds.swap
        case .withdraw,
             .interestWithdraw:
            return LocalizationIds.withdraw
        }
    }
}
