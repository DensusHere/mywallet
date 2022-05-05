// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
@testable import FeatureAuthenticationDomain
import ToolKit
import WalletPayloadKit

extension WalletCreationService {
    // swiftlint:disable line_length
    public static func mock() -> Self {
        WalletCreationService(
            createWallet: { _, _, _ -> AnyPublisher<WalletCreatedContext, WalletCreationServiceError> in
                .failure(WalletCreationServiceError.creationFailure(.genericFailure))
            },
            importWallet: { _, _, _, _ -> AnyPublisher<Either<WalletCreatedContext, EmptyValue>, WalletCreationServiceError> in
                .failure(.creationFailure(.genericFailure))
            },
            setResidentialInfo: { _, _ -> AnyPublisher<Void, Never> in
                .just(())
            }
        )
    }
}