// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import ComposableArchitecture
import FeatureCoinDomain
import MoneyKit
import SwiftUI

public enum CoinViewError: Error, Equatable {
    case failedToLoad
}

public struct CoinViewState: Equatable {
    public let currency: CryptoCurrency
    public var accounts: [Account.Snapshot]
    public var error: CoinViewError?
    public var assetInformation: AssetInformation?
    public var interestRate: Double?
    public var kycStatus: KYCStatus?
    public var isFavorite: Bool?
    public var graph: GraphViewState

    var appMode: AppMode?

    var swapButton: ButtonAction? {
        guard appMode != .both else {
            return nil
        }
        let swapDisabled = !accounts.hasPositiveBalanceForSelling
        let swapAction = ButtonAction.swap(disabled: swapDisabled)
        let action = action(swapAction, whenAccountCan: .swap)
        return action
    }

    @BindableState public var account: Account.Snapshot?
    @BindableState public var explainer: Account.Snapshot?

    var actions: [ButtonAction] {
        appMode == .both ? defaultCoinActions() : superAppCoinActions()
    }

    private func defaultCoinActions() -> [ButtonAction] {
        if !currency.isTradable || accounts.isEmpty {
            return accounts.hasPositiveBalanceForSelling ? [.send()] : []
        }
        let (buy, sell, send, receive) = (
            action(.buy(), whenAccountCan: .buy),
            action(.sell(), whenAccountCan: .sell),
            action(.send(), whenAccountCan: .send),
            action(.receive(), whenAccountCan: .receive)
        )

        if kycStatus?.canSellCrypto == false || !accounts.hasPositiveBalanceForSelling {
            return [receive, buy].compactMap { $0 }
        }

        let actions = [sell, buy].compactMap { $0 }
        if actions.isEmpty {
            return [send, receive].compactMap { $0 }
        } else {
            return actions
        }
    }

    private func superAppCoinActions() -> [ButtonAction] {
        let sellingDisabled = kycStatus?.canSellCrypto == false || !accounts.hasPositiveBalanceForSelling
        let sell = ButtonAction.sell(disabled: sellingDisabled)
        let buy = ButtonAction.buy(disabled: false)
        let receive = ButtonAction.receive(disabled: false)
        let send = ButtonAction.send(disabled: sellingDisabled)

        if !currency.isTradable || accounts.isEmpty {
            return [send]
        }

        guard appMode != .defi else {
            return [receive, send]
        }

        return [sell, buy]
    }

    private func action(_ action: ButtonAction, whenAccountCan accountAction: Account.Action) -> ButtonAction? {
        accounts.contains(where: { account in account.actions.contains(accountAction) }) ? action : nil
    }

    public init(
        currency: CryptoCurrency,
        kycStatus: KYCStatus? = nil,
        accounts: [Account.Snapshot] = [],
        assetInformation: AssetInformation? = nil,
        interestRate: Double? = nil,
        error: CoinViewError? = nil,
        isFavorite: Bool? = nil,
        graph: GraphViewState = GraphViewState()
    ) {
        self.currency = currency
        self.kycStatus = kycStatus
        self.accounts = accounts
        self.assetInformation = assetInformation
        self.interestRate = interestRate
        self.error = error
        self.isFavorite = isFavorite
        self.graph = graph
    }
}

extension CryptoCurrency {

    var isTradable: Bool {
        supports(product: .custodialWalletBalance) || supports(product: .privateKey)
    }
}
