import ComposableArchitecture
import MoneyKit

public enum AppModeSwitcherAction: Equatable, BindableAction {
    case onInit
    case onTradingTapped
    case onDefiTapped
    case onRecoveryPhraseStatusFetched(isBackedUp: Bool, isSkipped: Bool)
    case binding(BindingAction<AppModeSwitcherState>)
    case defiWalletIntro(DefiWalletIntroAction)
    case dismiss
}
