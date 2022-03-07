// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Combine
import ComposableArchitecture
import ComposableNavigation
import FeatureAuthenticationDomain
import ToolKit

// MARK: - Type

public enum SkipUpgradeAction: Equatable, NavigationAction {

    // MARK: - Transitions and Navigations

    case route(RouteIntent<SkipUpgradeRoute>?)
    case returnToUpgradeButtonTapped

    // MARK: - Local Actions

    case credentials(CredentialsAction)
}

// MARK: - Properties

public struct SkipUpgradeState: Equatable, NavigationState {

    // MARK: - Navigations

    public var route: RouteIntent<SkipUpgradeRoute>?

    // MARK: - WalletInfo

    var walletInfo: WalletInfo

    // MARK: - Local States

    var credentialsState: CredentialsState?

    init(walletInfo: WalletInfo) {
        self.walletInfo = walletInfo
    }
}

struct SkipUpgradeEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let deviceVerificationService: DeviceVerificationServiceAPI
    let errorRecorder: ErrorRecording
    let featureFlagsService: FeatureFlagsServiceAPI
    let analyticsRecorder: AnalyticsEventRecorderAPI
    let walletRecoveryService: WalletRecoveryService
    let walletCreationService: WalletCreationService
    let walletFetcherService: WalletFetcherService
    let accountRecoveryService: AccountRecoveryServiceAPI

    init(
        mainQueue: AnySchedulerOf<DispatchQueue>,
        deviceVerificationService: DeviceVerificationServiceAPI,
        errorRecorder: ErrorRecording,
        featureFlagsService: FeatureFlagsServiceAPI,
        analyticsRecorder: AnalyticsEventRecorderAPI,
        walletRecoveryService: WalletRecoveryService,
        walletCreationService: WalletCreationService,
        walletFetcherService: WalletFetcherService,
        accountRecoveryService: AccountRecoveryServiceAPI
    ) {
        self.mainQueue = mainQueue
        self.deviceVerificationService = deviceVerificationService
        self.errorRecorder = errorRecorder
        self.featureFlagsService = featureFlagsService
        self.analyticsRecorder = analyticsRecorder
        self.walletRecoveryService = walletRecoveryService
        self.walletCreationService = walletCreationService
        self.walletFetcherService = walletFetcherService
        self.accountRecoveryService = accountRecoveryService
    }
}

let skipUpgradeReducer = Reducer.combine(
    credentialsReducer
        .optional()
        .pullback(
            state: \.credentialsState,
            action: /SkipUpgradeAction.credentials,
            environment: {
                CredentialsEnvironment(
                    mainQueue: $0.mainQueue,
                    deviceVerificationService: $0.deviceVerificationService,
                    errorRecorder: $0.errorRecorder,
                    featureFlagsService: $0.featureFlagsService,
                    analyticsRecorder: $0.analyticsRecorder,
                    walletRecoveryService: $0.walletRecoveryService,
                    walletCreationService: $0.walletCreationService,
                    walletFetcherService: $0.walletFetcherService,
                    accountRecoveryService: $0.accountRecoveryService
                )
            }
        ),
    Reducer<
        SkipUpgradeState,
        SkipUpgradeAction,
        SkipUpgradeEnvironment
    > { state, action, _ in
        switch action {

        // MARK: - Transitions and Navigations

        case .route(let route):
            if let routeValue = route?.route {
                switch routeValue {
                case .credentials:
                    state.credentialsState = .init(
                        walletPairingState: WalletPairingState(
                            emailAddress: state.walletInfo.wallet?.email ?? "",
                            emailCode: state.walletInfo.wallet?.emailCode,
                            walletGuid: state.walletInfo.wallet?.guid ?? ""
                        )
                    )
                }
            } else {
                state.credentialsState = nil
            }
            state.route = route
            return .none

        case .returnToUpgradeButtonTapped:
            return .none

        // MARK: - Local Reducers

        case .credentials:
            return .none
        }
    }
)
