// Copyright © Blockchain Luxembourg S.A. All rights reserved.

public enum ExchangeAccountsNetworkError: Error {
    /// An error thrown when the currency is not supported by Exchange.
    case unavailable
    /// An error thrown when the user doesn't have an Exchange account to fetch his Exchange address from
    case missingAccount
}
