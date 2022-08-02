// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit
import ToolKit

/// Represents all types of transactions the user can perform
public enum TransactionFlowAction {

    // Restores an existing order.
    case order(OrderDetails)
    /// Performs a buy. If `CryptoAccount` is `nil`, the users will be presented with a crypto currency selector.
    case buy(CryptoAccount?)
    /// Performs a sell. If `CryptoCurrency` is `nil`, the users will be presented with a crypto currency selector.
    case sell(CryptoAccount?)
    /// Performs a swap. If `CryptoCurrency` is `nil`, the users will be presented with a crypto currency selector.
    case swap(CryptoAccount?)
    /// Performs a send. If `BlockchainAccount` is `nil`, the users will be presented with a crypto account selector.
    case send(BlockchainAccount?, TransactionTarget?)
    /// Performs a receive. If `CryptoAccount` is `nil`, the users will be presented with a crypto account selector.
    case receive(CryptoAccount?)
    /// Performs an interest transfer.
    case interestTransfer(CryptoInterestAccount)
    /// Performs an interest withdraw.
    case interestWithdraw(CryptoInterestAccount)
    /// Performs a withdraw.
    case withdraw(FiatAccount)
    /// Performs a deposit.
    case deposit(FiatAccount)
    /// Signs a transaction
    case sign(sourceAccount: BlockchainAccount, destination: TransactionTarget)
}

extension TransactionFlowAction: Equatable {
    public static func == (lhs: TransactionFlowAction, rhs: TransactionFlowAction) -> Bool {
        switch (lhs, rhs) {
        case (.buy(let lhsAccount), .buy(let rhsAccount)),
             (.sell(let lhsAccount), .sell(let rhsAccount)),
             (.swap(let lhsAccount), .swap(let rhsAccount)),
             (.receive(let lhsAccount), .receive(let rhsAccount)):
            return lhsAccount?.identifier == rhsAccount?.identifier
        case (.interestTransfer(let lhsAccount), .interestTransfer(let rhsAccount)),
             (.interestWithdraw(let lhsAccount), .interestWithdraw(let rhsAccount)):
            return lhsAccount.identifier == rhsAccount.identifier
        case (.withdraw(let lhsAccount), .withdraw(let rhsAccount)),
             (.deposit(let lhsAccount), .deposit(let rhsAccount)):
            return lhsAccount.identifier == rhsAccount.identifier
        case (.order(let lhsOrder), .order(let rhsOrder)):
            return lhsOrder.identifier == rhsOrder.identifier
        case (.sign(let lhsAccount, let lhsDestination), .sign(let rhsAccount, let rhsDestination)):
            return lhsAccount.identifier == rhsAccount.identifier
                && lhsDestination.label == rhsDestination.label
        case (.send(let lhsFromAccount, let lhsDestination), .send(let rhsFromAccount, let rhsDestination)):
            return lhsFromAccount?.identifier == rhsFromAccount?.identifier
                && lhsDestination?.label == rhsDestination?.label
        default:
            return false
        }
    }
}

extension TransactionFlowAction {
    
    public var isCustodial: Bool {
        switch self {
        case .order:
            return true
        case .buy(let account):
            return account is TradingAccount
        case .sell(let account):
            return account is TradingAccount
        case .swap(let account):
            return account is TradingAccount
        case .send(let account, _):
            return account is TradingAccount
        case .receive(let account):
            return account is TradingAccount
        case .interestTransfer:
            return true
        case .interestWithdraw:
            return true
        case .withdraw:
            return true
        case .deposit:
            return true
        case .sign(let account, _):
            return account is TradingAccount
        }
    }
}

// swiftlint:disable switch_case_on_newline
extension TransactionFlowAction {
    public var asset: AssetAction {
        switch self {
        case .buy: return .buy
        case .sell: return .sell
        case .swap: return .swap
        case .send: return .send
        case .receive: return .receive
        case .order: return .buy
        case .deposit: return .deposit
        case .withdraw: return .withdraw
        case .interestTransfer: return .interestTransfer
        case .interestWithdraw: return .interestWithdraw
        case .sign: return .sign
        }
    }
}
