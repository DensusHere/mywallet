// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors
import MoneyKit
import PlatformKit

public enum InterestAccountWithdrawRepositoryError: Error {
    case networkError(Error)
}

public protocol InterestAccountWithdrawRepositoryAPI: AnyObject {

    func createInterestAccountWithdrawal(
        _ amount: MoneyValue,
        address: String,
        currencyCode: String
    ) -> AnyPublisher<Void, InterestAccountWithdrawRepositoryError>
}
