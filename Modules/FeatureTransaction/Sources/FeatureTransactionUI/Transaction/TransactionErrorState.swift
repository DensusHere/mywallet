// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import FeatureOpenBankingDomain
import FeatureTransactionDomain
import MoneyKit
import NabuNetworkError
import NetworkError
import PlatformKit
import SwiftUI
import ToolKit

enum TransactionErrorState: Equatable {
    /// The tansaction is valid
    case none
    /// Any other error
    case unknownError
    /// A network error
    case nabuError(NabuError)
    /// The balance of the source account is not sufficient to execute the transaction.
    /// Takes the balance of the transaction's source in the input currency, the desired amount, the source currency and the target currency.
    case insufficientFunds(MoneyValue, MoneyValue, CurrencyType, CurrencyType)
    /// The available balance of the source account is not sufficient to conver fees required to pay for the transaction.
    /// Takes the total fees required for the transaction and the balance for the source account.
    case belowFees(MoneyValue, MoneyValue)
    /// The amount is below the user's minimum limit for the transaction.
    /// Takes the minimum valid amount required to execute the transaction.
    case belowMinimumLimit(MoneyValue)
    /// The amount is over the maximum allowed for this transaction for the specific source.
    /// Takes the maximum limit, the account name, and the desired amount.
    case overMaximumSourceLimit(MoneyValue, String, MoneyValue)
    /// The amount is over the user's maximum limit for the transaction.
    /// Takes the applicable Periodic Limit that has been exceeded, the available limit, and an optional suggested upgrade.
    case overMaximumPersonalLimit(EffectiveLimit, MoneyValue, TransactionValidationState.LimitsUpgrade?)

    // MARK: - Not checked

    case addressIsContract
    case invalidAddress
    case invalidPassword
    case optionInvalid
    case pendingOrdersLimitReached
    case transactionInFlight
    case fatalError(FatalTransactionError)
}

extension TransactionErrorState {

    var label: String {
        Mirror(reflecting: self).children.first?.label ?? String(describing: self)
    }

    var fatalError: FatalTransactionError? {
        switch self {
        case .fatalError(let error):
            return error
        default:
            return nil
        }
    }
}

extension TransactionErrorState {

    func analytics(for action: AssetAction) -> ClientEvent? {

        guard self != .none else { return nil }

        let title = recoveryWarningTitle(for: action)
        let error = title == nil ? "OOPS_ERROR" : label.snakeCase().uppercased()
        let oops = "Oops! Something went wrong"
        let action = action.description.snakeCase().uppercased()

        if let nabuError = extract(NabuError.self, from: self) {
            return ClientEvent.clientError(
                error: error,
                networkEndpoint: nil,
                networkErrorCode: nabuError.code.rawValue.description,
                networkErrorDescription: nabuError.serverDescription,
                networkErrorId: nabuError.id,
                networkErrorType: nabuError.type.rawValue,
                source: "NABU",
                title: title.or(oops),
                action: action
            )
        } else if let networkError = extract(NetworkError.self, from: self) {
            return ClientEvent.clientError(
                error: error,
                networkEndpoint: networkError.endpoint,
                networkErrorCode: networkError.code?.description,
                networkErrorDescription: networkError.description,
                networkErrorId: nil,
                networkErrorType: "NETWORK",
                source: "NABU",
                title: title.or(oops),
                action: action
            )
        } else if let openBankingError = extract(OpenBanking.Error.self, from: self) {
            return ClientEvent.clientError(
                error: error,
                networkEndpoint: nil,
                networkErrorCode: nil,
                networkErrorDescription: openBankingError.description,
                networkErrorId: nil,
                networkErrorType: openBankingError.code,
                source: "NABU",
                title: title.or(oops),
                action: action
            )
        } else {
            return ClientEvent.clientError(
                error: error,
                networkEndpoint: nil,
                networkErrorCode: nil,
                networkErrorDescription: extract(CustomStringConvertible.self, from: self).description,
                networkErrorId: nil,
                networkErrorType: label.snakeCase().uppercased(),
                source: "CLIENT",
                title: title.or(oops),
                action: action
            )
        }
    }
}