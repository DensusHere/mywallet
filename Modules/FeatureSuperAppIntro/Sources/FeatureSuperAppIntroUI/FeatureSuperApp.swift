import ComposableArchitecture
import Foundation

public struct FeatureSuperAppIntro: ReducerProtocol {

    public init (onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    public func reduce(into state: inout State, action: Action) -> ComposableArchitecture.Effect<Action, Never> {
        switch action {
        case .didChangeStep(let step):
            state.currentStep = step
            return .none

        case .onDismiss:
            onDismiss()
            return .none
        }
    }

    var onDismiss: () -> Void

    public struct State: Equatable {
        public init(
            flow: Flow = .legacy
        ) {
            self.flow = flow
            self.steps = flow.steps
            self.currentStep = flow.steps.first ?? .walletJustGotBetter
        }

        public enum Flow: Hashable {
            case legacy
            case existingUser
            case newUser

            var steps: [Step] {
                switch self {
                case .legacy:
                    return Step.legacy
                case .newUser:
                    return Step.newUser
                case .existingUser:
                    return Step.existingUser
                }
            }
        }

        public enum Step: Hashable, Identifiable {
            public var id: Self { self }

            public static let legacy: [Self] = [.walletJustGotBetter, .newWayToNavigate, .newHomeForDefi, .tradingAccount]
            public static let newUser: [Self] = [.welcomeNewUserV1, .tradingAccountV1, .defiWalletV1]
            public static let existingUser: [Self] = [.welcomeExistingUserV1, .tradingAccountV1, .defiWalletV1]

            // Legacy Intro with previous screens
            case walletJustGotBetter
            case newWayToNavigate
            case newHomeForDefi
            case tradingAccount

            // SuperApp v1 with new skin
            case welcomeNewUserV1
            case welcomeExistingUserV1
            case tradingAccountV1
            case defiWalletV1
        }

        private let scrollEffectTransitionDistance: CGFloat = 300

        var scrollOffset: CGFloat = 0
        var currentStep: Step
        var flow: Flow
        var steps: [Step]

        var gradientBackgroundOpacity: Double {
            switch scrollOffset {
            case _ where scrollOffset >= 0:
                return 1
            case _ where scrollOffset <= -scrollEffectTransitionDistance:
                return 0
            default:
                return 1 - Double(scrollOffset / -scrollEffectTransitionDistance)
            }
        }
    }

    public enum Action: Equatable {
        case didChangeStep(State.Step)
        case onDismiss
    }
}
