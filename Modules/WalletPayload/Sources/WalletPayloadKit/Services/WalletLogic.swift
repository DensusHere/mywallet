// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import Foundation
import MetadataKit
import ToolKit

protocol WalletLogicAPI {
    /// Initialises a `Wallet` using the given payload data
    /// - Parameter password: A `String` value representing user's password
    /// - Parameter secondPassword: A `String` value representing user's second password
    /// - Returns: `AnyPublisher<WalletState, WalletError>`
    func initialize(
        with password: String,
        secondPassword: String
    ) -> AnyPublisher<WalletState, WalletError>

    /// Initialises a `Wallet` using the given payload data
    /// - Parameter payload: A `WalletPayload` value
    /// - Parameter decryptedWallet: A `Data` value representing a valid decrypted wallet payload
    /// - Returns: `AnyPublisher<WalletState, WalletError>`
    func initialize(
        with password: String,
        payload: WalletPayload,
        decryptedWallet: Data
    ) -> AnyPublisher<WalletState, WalletError>

    /// Initialises a `Wallet` from metadata using the given seed phrase
    /// - Parameter mnemonic: A `String` value representing the users mnemonic words
    /// - Parameter queue: A `DispatchQueue` for operations to be performed on
    /// - Returns: `AnyPublisher<WalletState, WalletError>`
    func initialize(
        with mnemonic: String,
        on queue: DispatchQueue
    ) -> AnyPublisher<MetadataRecoveryCredentials, WalletError>

    /// Initialises a `Wallet` after recovery using the given payload data
    /// - Parameter password: A `String` value representing user's password
    /// - Parameter payload: A `WalletPayload` value
    /// - Parameter decryptedWallet: A `Data` value representing a valid decrypted wallet payload
    /// - Returns: `AnyPublisher<WalletState, WalletError>`
    func initializeAfterMetadataRecovery(
        with password: String,
        payload: WalletPayload,
        decryptedWallet: Data
    ) -> AnyPublisher<WalletState, WalletError>
}

final class WalletLogic: WalletLogicAPI {

    private let holder: WalletHolderAPI
    private let decoder: WalletDecoding
    private let metadata: MetadataServiceAPI
    private let notificationCenter: NotificationCenter

    #warning("TODO: This should be removed, pass opaque context from initialize methods instead")
    private var tempPassword: String?

    init(
        holder: WalletHolderAPI,
        decoder: @escaping WalletDecoding,
        metadata: MetadataServiceAPI,
        notificationCenter: NotificationCenter
    ) {
        self.holder = holder
        self.decoder = decoder
        self.metadata = metadata
        self.notificationCenter = notificationCenter
    }

    func initialize(
        with password: String,
        secondPassword: String
    ) -> AnyPublisher<WalletState, WalletError> {
        holder.walletStatePublisher
            .first()
            .flatMap { walletState -> AnyPublisher<WalletState, WalletError> in
                guard let walletState = walletState else {
                    return .failure(.payloadNotFound)
                }
                return .just(walletState)
            }
            .flatMap { walletState -> AnyPublisher<Wrapper, WalletError> in
                guard let wrapper = walletState.wrapper else {
                    return .failure(.initialization(.missingWallet))
                }
                return .just(wrapper)
            }
            .flatMap { [initialiseMetadataWithSecondPassword, tempPassword] wrapper
                -> AnyPublisher<WalletState, WalletError> in
                guard let tempPassword = tempPassword else {
                    return .failure(.initialization(.unknown))
                }
                return initialiseMetadataWithSecondPassword(wrapper, tempPassword, secondPassword)
            }
            .eraseToAnyPublisher()
    }

    func initialize(
        with password: String,
        payload: WalletPayload,
        decryptedWallet: Data
    ) -> AnyPublisher<WalletState, WalletError> {
        decoder(payload, decryptedWallet)
            .flatMap { [holder] wrapper -> AnyPublisher<Wrapper?, WalletError> in
                holder.hold(walletState: .partially(loaded: .justWrapper(wrapper)))
                    .map(\.wrapper)
                    .setFailureType(to: WalletError.self)
                    .eraseToAnyPublisher()
            }
            .flatMap { wrapper -> AnyPublisher<Wrapper, WalletError> in
                guard let wrapper = wrapper else {
                    return .failure(.initialization(.missingWallet))
                }
                return .just(wrapper)
            }
            .flatMap { [initialiseMetadata] wrapper -> AnyPublisher<WalletState, WalletError> in
                initialiseMetadata(wrapper, password)
            }
            .eraseToAnyPublisher()
    }

    func initializeAfterMetadataRecovery(
        with password: String,
        payload: WalletPayload,
        decryptedWallet: Data
    ) -> AnyPublisher<WalletState, WalletError> {
        holder.walletStatePublisher
            .first()
            .flatMap { walletState -> AnyPublisher<MetadataState, WalletError> in
                guard let metadataState = walletState?.metadata else {
                    return .failure(.initialization(.metadataInitialization))
                }
                return .just(metadataState)
            }
            .flatMap { [decoder] metadataState -> AnyPublisher<(Wrapper, MetadataState), WalletError> in
                decoder(payload, decryptedWallet)
                    .map { ($0, metadataState) }
                    .eraseToAnyPublisher()
            }
            .flatMap { [holder] wrapper, metadataState -> AnyPublisher<WalletState, WalletError> in
                holder.hold(walletState: .loaded(wrapper: wrapper, metadata: metadataState))
                    .first()
                    .mapError()
                    .eraseToAnyPublisher()
            }
            .handleEvents(receiveOutput: { [notifyReactiveWallet] _ in
                // inform ReactiveWallet that we're initialised
                notifyReactiveWallet()
            })
            .eraseToAnyPublisher()
    }

    func initialize(
        with mnemonic: String,
        on queue: DispatchQueue
    ) -> AnyPublisher<MetadataRecoveryCredentials, WalletError> {
        metadata.initializeAndRecoverCredentials(from: mnemonic)
            .subscribe(on: queue)
            .receive(on: queue)
            .mapError { _ in WalletError.initialization(.metadataInitialization) }
            .flatMap { [holder] context -> AnyPublisher<RecoveryContext, WalletError> in
                holder.hold(walletState: .partially(loaded: .justMetadata(context.metadataState)))
                    .setFailureType(to: WalletError.self)
                    .map { _ in context }
                    .first()
                    .eraseToAnyPublisher()
            }
            .map { context in
                MetadataRecoveryCredentials(
                    guid: context.guid,
                    sharedKey: context.sharedKey,
                    password: context.password
                )
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Private

    private func initialiseMetadataWithSecondPassword(
        with wrapper: Wrapper,
        password: String,
        secondPassword: String
    ) -> AnyPublisher<WalletState, WalletError> {
        guard wrapper.wallet.doubleEncrypted else {
            fatalError("This method should only be called if a secondPassword is needed")
        }
        return initialiseMetadata(with: wrapper, password: password, secondPassword: secondPassword)
    }

    private func initialiseMetadata(
        with wrapper: Wrapper,
        password: String
    ) -> AnyPublisher<WalletState, WalletError> {
        if wrapper.wallet.doubleEncrypted {
            tempPassword = password
            return .failure(.initialization(.needsSecondPassword))
        }
        return initialiseMetadata(with: wrapper, password: password, secondPassword: nil)
    }

    private func initialiseMetadata(
        with wrapper: Wrapper,
        password: String,
        secondPassword: String?
    ) -> AnyPublisher<WalletState, WalletError> {
        provideMetadataInput(
            password: password,
            secondPassword: secondPassword,
            wallet: wrapper.wallet
        )
        .map { input in
            (input, wrapper)
        }
        .flatMap { [metadata] input, wrapper -> AnyPublisher<WalletState, WalletError> in
            metadata.initialize(
                credentials: input.credentials,
                masterKey: input.masterKey,
                payloadIsDoubleEncrypted: input.payloadIsDoubleEncrypted
            )
            .map { metadataState -> WalletState in
                .loaded(wrapper: wrapper, metadata: metadataState)
            }
            .replaceError(with: .initialization(.metadataInitialization))
            .eraseToAnyPublisher()
        }
        .flatMap { [holder] walletState
            -> AnyPublisher<WalletState, WalletError> in
            holder.hold(walletState: walletState)
                .setFailureType(to: WalletError.self)
                .eraseToAnyPublisher()
        }
        .handleEvents(receiveOutput: { [notifyReactiveWallet] _ in
            // inform ReactiveWallet that we're initialised
            notifyReactiveWallet()
        })
        .eraseToAnyPublisher()
    }

    private func notifyReactiveWallet() {
        notificationCenter.post(Notification(name: .walletInitialized))
        notificationCenter.post(Notification(name: .walletMetadataLoaded))
    }
}

struct MetadataInput {
    let credentials: Credentials
    let masterKey: MasterKey
    let payloadIsDoubleEncrypted: Bool
}

func provideMetadataInput(
    password: String,
    secondPassword: String?,
    wallet: NativeWallet
) -> AnyPublisher<MetadataInput, WalletError> {
    getSeedHex(from: wallet, secondPassword: secondPassword)
        .flatMap(masterKeyFrom(seedHex:))
        .map { masterKey -> MetadataInput in
            let credentials = Credentials(
                guid: wallet.guid,
                sharedKey: wallet.sharedKey,
                password: password
            )
            return MetadataInput(
                credentials: credentials,
                masterKey: masterKey,
                payloadIsDoubleEncrypted: wallet.doubleEncrypted
            )
        }
        .publisher
        .eraseToAnyPublisher()
}

private func masterKeyFrom(seedHex: String) -> Result<MasterKey, WalletError> {
    MasterKey.from(seedHex: seedHex)
        .mapError { _ -> WalletError in
            .initialization(.metadataInitialization)
        }
}
