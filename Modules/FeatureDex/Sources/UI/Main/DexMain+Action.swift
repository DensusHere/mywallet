// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import DelegatedSelfCustodyDomain
import Errors
import FeatureDexDomain

extension DexMain {
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)

        case destinationAction(DexCell.Action)
        case sourceAction(DexCell.Action)

        case onAppear
        case didTapSettings
        case didTapPreview
        case didTapAllowance

        case refreshAllowance
        case onAllowance(Result<DexAllowanceResult, UX.Error>)
        case updateAllowance(DexAllowanceResult?)

        case onBalances(Result<[DexBalance], UX.Error>)
        case updateAvailableBalances([DexBalance])

        case refreshQuote
        case onQuote(Result<DexQuoteOutput, UX.Error>?)
    }
}
