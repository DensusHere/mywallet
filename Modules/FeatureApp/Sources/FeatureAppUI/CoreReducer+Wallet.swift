// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Combine
import ComposableArchitecture
import DIKit
import ERC20Kit
import FeatureAppDomain
import FeatureAuthenticationDomain
import FeatureAuthenticationUI
import FeatureSettingsDomain
import Localization
import PlatformKit
import PlatformUIKit
import RemoteNotificationsKit
import ToolKit
import UIKit
import WalletPayloadKit

/// Used for canceling publishers
enum WalletCancelations {
    struct FetchId: Hashable {}
    struct DecryptId: Hashable {}
    struct AuthenticationId: Hashable {}
    struct InitializationId: Hashable {}
    struct UpgradeId: Hashable {}
    struct CreateId: Hashable {}
    struct RestoreId: Hashable {}
    struct RestoreFailedId: Hashable {}
    struct AssetInitializationId: Hashable {}
    struct SecondPasswordId: Hashable {}
    struct ForegroundInitCheckId: Hashable {}
}

public enum WalletAction: Equatable {
    case walletFetched(Result<WalletFetchedContext, WalletError>)
    case fetchWithSecondPassword(password: String, secondPassword: String)
}

extension Reducer where State == CoreAppState, Action == CoreAppAction, Environment == CoreAppEnvironment {
    /// Returns a combined reducer that handles all the wallet related actions
    func walletReducer() -> Self {
        combined(
            with: Reducer { _, action, environment in
                switch action {
                case .wallet(.walletFetched(.success(let value))):
                    // convert to WalletDecryption model
                    let decryption = WalletDecryption(
                        guid: value.guid,
                        sharedKey: value.sharedKey,
                        passwordPartHash: value.passwordPartHash
                    )
                    // send the legacy actions
                    // this is temporary once we completely move to native wallet login
                    return .merge(
                        Effect(value: .didDecryptWallet(decryption)),
                        Effect(value: .authenticated(.success(true)))
                    )

                case .wallet(.walletFetched(.failure(.initialization(.needsSecondPassword)))):
                    return environment.secondPasswordPrompter
                        .secondPasswordIfNeeded(type: .login)
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .cancellable(id: WalletCancelations.SecondPasswordId(), cancelInFlight: true)
                        .map { result in
                            switch result {
                            case .success(let secondPassword):
                                guard let secondPassword = secondPassword else {
                                    return .none
                                }
                                return .wallet(.fetchWithSecondPassword(password: "", secondPassword: secondPassword))
                            case .failure:
                                unimplemented("TODO: Provide correct error handling")
                            }
                        }

                case .wallet(.walletFetched(.failure(let error))):
                    // hide loader if any
                    environment.loadingViewPresenter.hide()
                    // show alert
                    let buttons: CoreAlertAction.Buttons = .init(
                        primary: .default(
                            TextState(verbatim: LocalizationConstants.ErrorAlert.button),
                            action: .send(.alert(.dismiss))
                        ),
                        secondary: nil
                    )
                    let alertAction = CoreAlertAction.show(
                        title: LocalizationConstants.Errors.error,
                        message: error.errorDescription ?? LocalizationConstants.Errors.genericError,
                        buttons: buttons
                    )
                    return .merge(
                        Effect(value: .alert(alertAction)),
                        .cancel(id: WalletCancelations.FetchId()),
                        Effect(value: .onboarding(.handleWalletDecryptionError))
                    )

                case .wallet(.fetchWithSecondPassword(let password, let secondPassword)):
                    return environment.walletService
                        .fetchUsingSecPassword(password, secondPassword)
                        .receive(on: environment.mainQueue)
                        .catchToEffect()
                        .cancellable(id: WalletCancelations.FetchId(), cancelInFlight: true)
                        .map { CoreAppAction.wallet(.walletFetched($0)) }
                default:
                    return .none
                }
            }
        )
    }
}
