// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import ToolKit

public struct NativeWalletFlagEnabled {
    public let publisher: AnyPublisher<Bool, Never>
    public init<P: Publisher>(_ publisher: P) where P.Output == Bool, P.Failure == Never {
        self.publisher = publisher.eraseToAnyPublisher()
    }
}

/// Useful top-level method to check whether nativeWallet feature flag is enabled or not
/// - Parameters:
///   - service: A `FeatureFlagsServiceAPI`
/// - Returns: An `AnyPublisher<Bool, Never>` that determines whether the flag is enabled or not
public func nativeWalletFlagEnabled(
    featureFlag: NativeWalletFlagEnabled = resolve()
) -> AnyPublisher<Bool, Never> {
    featureFlag.publisher
}

/// Useful top-level method to check whether native wallet creation feature flag is enabled or not
public func nativeWalletCreationFlagEnabled(
    service: FeatureFlagsServiceAPI = resolve()
) -> AnyPublisher<Bool, Never> {
    service.isEnabled(.nativeWalletCreation)
}

/// Useful top-left method that output an Either type of values old and new.
/// - Parameters:
///   - old: An old implementation to be used
///   - new: A new  implementation to be used
/// - Returns: `Either<Old, New>`
public func nativeWalletEnabledUseImpl<Old, New>(
    old: Old,
    new: New
) -> AnyPublisher<Either<Old, New>, Never> {
    nativeWalletFlagEnabled()
        .map { isEnabled in
            guard isEnabled else {
                return Either.left(old)
            }
            return Either.right(new)
        }
        .eraseToAnyPublisher()
}

public typealias NativeWalletEnabledUseImpl<Old, New> = (Old, New) -> AnyPublisher<Either<Old, New>, Never>
