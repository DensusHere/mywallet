// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import FeatureTransactionDomain
import Localization
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxSwift
import ToolKit

final class BuyPendingTransactionStateProvider: PendingTransactionStateProviding {

    private typealias LocalizationIds = LocalizationConstants.Transaction.Buy.Completion

    private let coreBuyIcon: CompositeStatusViewType.Composite.BaseViewType = .templateImage(
        name: "plus-icon",
        bundle: .platformUIKit,
        templateColor: .white
    )

    // MARK: - PendingTransactionStateProviding

    func connect(state: Observable<TransactionState>) -> Observable<PendingTransactionPageState> {
        state.map(weak: self) { (self, state) in
            switch state.executionStatus {
            case .inProgress,
                 .notStarted:
                return self.inProgress(state: state)
            case .pending:
                return self.pending(state: state)
            case .completed:
                return self.success(state: state)
            case .error:
                return self.failed(state: state)
            }
        }
    }

    // MARK: - Private Functions

    private func success(state: TransactionState) -> PendingTransactionPageState {
        guard let destinationCurrency = state.destination?.currencyType else {
            impossible("Expected a destination to there for a transaction that has succeeded")
        }
        return .init(
            title: LocalizationIds.Success.title,
            subtitle: String(
                format: LocalizationIds.Success.description,
                destinationCurrency.name
            ),
            compositeViewType: .composite(
                .init(
                    baseViewType: coreBuyIcon,
                    sideViewAttributes: .init(
                        type: .image(.local(name: "v-success-icon", bundle: .platformUIKit)),
                        position: .radiusDistanceFromCenter
                    ),
                    backgroundColor: .primaryButton,
                    cornerRadiusRatio: 0.5
                )
            ),
            effect: .complete,
            primaryButtonViewModel: .primary(with: LocalizationIds.Success.action),
            action: state.action
        )
    }

    private func inProgress(state: TransactionState) -> PendingTransactionPageState {
        let fiat = state.amount
        let crypto = state.pendingTransaction?.confirmations.compactMap { confirmation -> MoneyValue? in
            if case .buyCryptoValue(let value) = confirmation {
                return MoneyValue(cryptoValue: value.baseValue)
            } else {
                return nil
            }
        }.first
        let title = String(
            format: LocalizationIds.InProgress.title,
            crypto?.displayString ?? "",
            fiat.displayString
        )
        return .init(
            title: title,
            subtitle: LocalizationIds.InProgress.description,
            compositeViewType: .composite(
                .init(
                    baseViewType: coreBuyIcon,
                    sideViewAttributes: .init(type: .loader, position: .radiusDistanceFromCenter),
                    backgroundColor: .primaryButton,
                    cornerRadiusRatio: 0.5
                )
            ),
            action: state.action
        )
    }

    private func pending(state: TransactionState) -> PendingTransactionPageState {
        PendingTransactionPageState(
            title: LocalizationIds.Pending.title,
            subtitle: LocalizationIds.Pending.description,
            compositeViewType: .composite(
                .init(
                    baseViewType: coreBuyIcon,
                    sideViewAttributes: .init(
                        type: .image(.local(name: "clock-error-icon", bundle: .platformUIKit)),
                        position: .radiusDistanceFromCenter
                    ),
                    backgroundColor: .primaryButton,
                    cornerRadiusRatio: 0.5
                )
            ),
            effect: .complete,
            primaryButtonViewModel: .primary(with: LocalizationConstants.okString),
            action: state.action
        )
    }

    private func failed(state: TransactionState) -> PendingTransactionPageState {
        if let details = state.order as? OrderDetails, let code = details.error {
            return bankingError(in: state, error: .code(code), icon: coreBuyIcon)
        }
        return .init(
            title: state.transactionErrorTitle,
            subtitle: state.transactionErrorDescription,
            compositeViewType: .composite(
                .init(
                    baseViewType: coreBuyIcon,
                    sideViewAttributes: .init(
                        type: .image(.local(name: "circular-error-icon", bundle: .platformUIKit)),
                        position: .radiusDistanceFromCenter
                    ),
                    backgroundColor: .primaryButton,
                    cornerRadiusRatio: 0.5
                )
            ),
            effect: .close,
            primaryButtonViewModel: .primary(with: LocalizationConstants.okString),
            action: state.action,
            error: state.errorState
        )
    }
}
