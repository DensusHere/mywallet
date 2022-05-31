// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation
import MetadataKit
import NetworkError
import ToolKit
import WalletCore

public enum WalletCreateError: LocalizedError, Equatable {
    case genericFailure
    case expectedEncodedPayload
    case encryptionFailure
    case uuidFailure
    case verificationFailure(EncryptAndVerifyError)
    case mnemonicFailure(MnemonicProviderError)
    case encodingError(WalletEncodingError)
    case networkError(NetworkError)
    case legacyError(LegacyWalletCreationError)
    case usedAccountsFinderError(UsedAccountsFinderError)
}

struct WalletCreationContext: Equatable {
    let mnemonic: String
    let guid: String
    let sharedKey: String
    let accountName: String
    let totalAccounts: Int
}

typealias UUIDProvider = () -> AnyPublisher<(guid: String, sharedKey: String), WalletCreateError>
typealias GenerateWalletProvider = (WalletCreationContext) -> Result<NativeWallet, WalletCreateError>
typealias GenerateWrapperProvider = (NativeWallet, String, WalletVersion) -> Wrapper

public protocol WalletCreatorAPI {

    /// Creates a new wallet using the given email and password.
    /// - Returns: `AnyPublisher<WalletCreation, WalletCreateError>`
    func createWallet(
        email: String,
        password: String,
        accountName: String,
        language: String
    ) -> AnyPublisher<WalletCreation, WalletCreateError>

    /// Imports and creates a new wallet from the mnemonic and using the given email and password.
    /// - Returns: `AnyPublisher<WalletCreation, WalletCreateError>`
    func importWallet(
        mnemonic: String,
        email: String,
        password: String,
        accountName: String,
        language: String
    ) -> AnyPublisher<WalletCreation, WalletCreateError>
}

final class WalletCreator: WalletCreatorAPI {

    private let entropyService: RNGServiceAPI
    private let walletEncoder: WalletEncodingAPI
    private let encryptor: PayloadCryptoAPI
    private let createWalletRepository: CreateWalletRepositoryAPI
    private let usedAccountsFinder: UsedAccountsFinderAPI
    private let operationQueue: DispatchQueue
    private let uuidProvider: UUIDProvider
    private let generateWallet: GenerateWalletProvider
    private let generateWrapper: GenerateWrapperProvider
    private let checksumProvider: (Data) -> String

    init(
        entropyService: RNGServiceAPI,
        walletEncoder: WalletEncodingAPI,
        encryptor: PayloadCryptoAPI,
        createWalletRepository: CreateWalletRepositoryAPI,
        usedAccountsFinder: UsedAccountsFinderAPI,
        operationQueue: DispatchQueue,
        uuidProvider: @escaping UUIDProvider,
        generateWallet: @escaping GenerateWalletProvider,
        generateWrapper: @escaping GenerateWrapperProvider,
        checksumProvider: @escaping (Data) -> String
    ) {
        self.uuidProvider = uuidProvider
        self.walletEncoder = walletEncoder
        self.encryptor = encryptor
        self.createWalletRepository = createWalletRepository
        self.usedAccountsFinder = usedAccountsFinder
        self.operationQueue = operationQueue
        self.entropyService = entropyService
        self.generateWallet = generateWallet
        self.generateWrapper = generateWrapper
        self.checksumProvider = checksumProvider
    }

    func createWallet(
        email: String,
        password: String,
        accountName: String,
        language: String = "en"
    ) -> AnyPublisher<WalletCreation, WalletCreateError> {
        provideMnemonic(
            strength: .normal,
            queue: operationQueue,
            entropyProvider: entropyService.generateEntropy(count:)
        )
        .mapError(WalletCreateError.mnemonicFailure)
        .receive(on: operationQueue)
        .flatMap { [uuidProvider] mnemonic -> AnyPublisher<WalletCreationContext, WalletCreateError> in
            uuidProvider()
                .map { guid, sharedKey in
                    WalletCreationContext(
                        mnemonic: mnemonic,
                        guid: guid,
                        sharedKey: sharedKey,
                        accountName: accountName,
                        totalAccounts: 1
                    )
                }
                .eraseToAnyPublisher()
        }
        .flatMap { [processCreationOfWallet] context -> AnyPublisher<WalletCreation, WalletCreateError> in
            processCreationOfWallet(context, email, password, language)
        }
        .eraseToAnyPublisher()
    }

    func importWallet(
        mnemonic: String,
        email: String,
        password: String,
        accountName: String,
        language: String
    ) -> AnyPublisher<WalletCreation, WalletCreateError> {
        hdWallet(from: mnemonic)
            .subscribe(on: operationQueue)
            .receive(on: operationQueue)
            .map(\.seed.toHexString)
            .map { masterSeedHex -> (MetadataKit.PrivateKey, MetadataKit.PrivateKey) in
                let legacy = deriveMasterAccountKey(seedHex: masterSeedHex, type: .legacy)
                let bech32 = deriveMasterAccountKey(seedHex: masterSeedHex, type: .segwit)
                return (legacy, bech32)
            }
            .flatMap { [usedAccountsFinder] legacy, bech32 -> AnyPublisher<Int, WalletCreateError> in
                usedAccountsFinder
                    .findUsedAccounts(
                        batch: 10,
                        xpubRetriever: generateXpub(legacyKey: legacy, bech32Key: bech32)
                    )
                    .map { totalAccounts in
                        // we still need to create one account in case account discovery returned zero.
                        max(1, totalAccounts)
                    }
                    .mapError(WalletCreateError.usedAccountsFinderError)
                    .eraseToAnyPublisher()
            }
            .flatMap { [uuidProvider] totalAccounts -> AnyPublisher<WalletCreationContext, WalletCreateError> in
                uuidProvider()
                    .map { guid, sharedKey in
                        WalletCreationContext(
                            mnemonic: mnemonic,
                            guid: guid,
                            sharedKey: sharedKey,
                            accountName: accountName,
                            totalAccounts: totalAccounts
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .flatMap { [processCreationOfWallet] context -> AnyPublisher<WalletCreation, WalletCreateError> in
                processCreationOfWallet(context, email, password, language)
            }
            .eraseToAnyPublisher()
    }

    func hdWallet(
        from mnemonic: String
    ) -> AnyPublisher<WalletCore.HDWallet, WalletCreateError> {
        Deferred {
            Future<WalletCore.HDWallet, WalletCreateError> { promise in
                switch getHDWallet(from: mnemonic) {
                case .success(let wallet):
                    promise(.success(wallet))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Final process for creating a wallet
    ///  1. Create the wallet and wrapper
    ///  2. Encrypt and verify the wrapper
    ///  3. Encode the wrapper payload
    ///  4. Create the wallet on the backend
    ///  5. Return a `WalletCreation` or failure if any
    func processCreationOfWallet(
        context: WalletCreationContext,
        email: String,
        password: String,
        language: String
    ) -> AnyPublisher<WalletCreation, WalletCreateError> {
        generateWallet(context)
            .map { wallet -> Wrapper in
                generateWrapper(wallet, language, WalletVersion.v4)
            }
            .publisher
            .eraseToAnyPublisher()
            .flatMap { [walletEncoder, encryptor] wrapper -> AnyPublisher<EncodedWalletPayload, WalletCreateError> in
                encryptAndVerifyWrapper(
                    walletEncoder: walletEncoder,
                    encryptor: encryptor,
                    password: password,
                    wrapper: wrapper
                )
                .mapError(WalletCreateError.verificationFailure)
                .eraseToAnyPublisher()
            }
            .flatMap { [walletEncoder, checksumProvider] payload -> AnyPublisher<WalletCreationPayload, WalletCreateError> in
                walletEncoder.encode(payload: payload, applyChecksum: checksumProvider)
                    .mapError(WalletCreateError.encodingError)
                    .eraseToAnyPublisher()
            }
            .flatMap { [createWalletRepository] payload -> AnyPublisher<WalletCreationPayload, WalletCreateError> in
                createWalletRepository.createWallet(email: email, payload: payload)
                    .map { _ in payload }
                    .mapError(WalletCreateError.networkError)
                    .eraseToAnyPublisher()
            }
            .map { payload in
                WalletCreation(
                    guid: payload.guid,
                    sharedKey: payload.sharedKey,
                    password: password
                )
            }
            .eraseToAnyPublisher()
    }
}

/// Provides UUIDs to be used as guid and sharedKey in wallet creation
/// - Returns: `AnyPublisher<(guid: String, sharedKey: String), WalletCreateError>`
func uuidProvider() -> AnyPublisher<(guid: String, sharedKey: String), WalletCreateError> {
    let guid = UUID().uuidString.lowercased()
    let sharedKey = UUID().uuidString.lowercased()
    guard guid.count == 36 || sharedKey.count == 36 else {
        return .failure(.uuidFailure)
    }
    return .just((guid, sharedKey))
}

/// (LegacyKey, Bech32Key) -> (DerivationType, Index) -> String
func generateXpub(
    legacyKey: MetadataKit.PrivateKey,
    bech32Key: MetadataKit.PrivateKey
) -> XpubRetriever {
    { type, index -> String in
        switch type {
        case .legacy:
            return legacyKey.derive(at: .hardened(UInt32(index))).xpub
        case .segwit:
            return bech32Key.derive(at: .hardened(UInt32(index))).xpub
        }
    }
}
