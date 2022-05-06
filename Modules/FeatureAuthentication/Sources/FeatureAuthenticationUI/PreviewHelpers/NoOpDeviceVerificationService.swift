// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureAuthenticationDomain
import Foundation
import ToolKit

/// Intend for SwiftUI Previews and only available in DEBUG
final class NoOpDeviceVerificationService: DeviceVerificationServiceAPI {

    func authorizeLogin(emailCode: String) -> AnyPublisher<Void, DeviceVerificationServiceError> {
        .empty()
    }

    func sendDeviceVerificationEmail(
        to emailAddress: String
    ) -> AnyPublisher<Void, DeviceVerificationServiceError> {
        .empty()
    }

    func handleLoginRequestDeeplink(url deeplink: URL) -> AnyPublisher<WalletInfo, WalletInfoError> {
        .empty()
    }

    func pollForWalletInfo() -> AnyPublisher<
        Result<WalletInfo, WalletInfoPollingError>,
        DeviceVerificationServiceError
    > {
        .empty()
    }

    func authorizeVerifyDevice(
        from sessionToken: String,
        payload: String,
        confirmDevice: Bool?
    ) -> AnyPublisher<Void, AuthorizeVerifyDeviceError> {
        .empty()
    }
}

final class NoOpAccountRecoveryService: AccountRecoveryServiceAPI {
    func recoverUser(
        guid: String,
        sharedKey: String,
        userId: String,
        recoveryToken: String
    ) -> AnyPublisher<Void, AccountRecoveryServiceError> {
        .just(())
    }

    func resetVerificationStatus(
        guid: String,
        sharedKey: String
    ) -> AnyPublisher<Void, AccountRecoveryServiceError> {
        .failure(.failedToSaveOfflineToken(.offlineToken))
    }
}
