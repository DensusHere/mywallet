// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Combine
import CryptoSwift
import DIKit
import EthereumKit
import Foundation
import MetadataKit
import MoneyKit
import NetworkKit
import PlatformKit
import ToolKit
import WalletConnectNetworking
import WalletConnectPairing
import WalletConnectRelay
import WalletConnectSign
import Web3Wallet

public struct WalletConnectProposal: Equatable, Codable, Hashable {
    public let proposal: SessionV2.Proposal
    public let account: String
    public let networks: [EVMNetwork]
}

public enum WalletConnectProposalResult: Equatable, Codable, Hashable {
    case request(WalletConnectProposal)
    case failure(message: String?, metadata: AppMetadata)
}

extension AppMetadata: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(url)
        hasher.combine(description)
    }
}

final class WalletConnectServiceV2: WalletConnectServiceV2API {

    private let _sessionEvents: PassthroughSubject<SessionV2Event, Never> = .init()
    var sessionEvents: AnyPublisher<SessionV2Event, Never> {
        _sessionEvents.eraseToAnyPublisher()
    }

    private let _userEvents: PassthroughSubject<WalletConnectUserEvent, Never> = .init()
    var userEvents: AnyPublisher<WalletConnectUserEvent, Never> {
        _userEvents.eraseToAnyPublisher()
    }

    var sessions: AnyPublisher<[SessionV2], Never> {
        Web3Wallet.instance.sessionsPublisher
    }

    private var lifetimeBag: Set<AnyCancellable> = []
    private var bag: Set<AnyCancellable> = []

    private let productId: String
    private let app: AppProtocol
    private let enabledCurrenciesService: EnabledCurrenciesServiceAPI
    private let publicKeyProvider: WalletConnectPublicKeyProviderAPI
    private let accountProvider: WalletConnectAccountProviderAPI
    private let txTargetFactory: (WalletConnectSign.Request) -> (any TransactionTarget)?

    init(
        productId: String,
        app: AppProtocol,
        enabledCurrenciesService: EnabledCurrenciesServiceAPI,
        publicKeyProvider: WalletConnectPublicKeyProviderAPI,
        accountProvider: WalletConnectAccountProviderAPI,
        txTargetFactory: @escaping (WalletConnectSign.Request) -> (any TransactionTarget)? = { _ in nil }
    ) {
        self.productId = productId
        self.app = app
        self.enabledCurrenciesService = enabledCurrenciesService
        self.publicKeyProvider = publicKeyProvider
        self.accountProvider = accountProvider
        self.txTargetFactory = txTargetFactory

        app.publisher(for: blockchain.user.id)
            .map(\.value.isNotNil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] signedIn in
                if signedIn {
                    self?.setup()
                } else {
                    self?.bag = []
                }
            }
            .store(in: &lifetimeBag)
    }

    func setup() {
        Web3Wallet.instance
            .sessionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (sessions: [SessionV2]) in
                // Update sessions
            }.store(in: &bag)

        let settled = Web3Wallet.instance
            .sessionSettlePublisher
            .map { SessionV2Event.pairSettled(WalletConnectSessionV2(session: $0)) }
            .eraseToAnyPublisher()

        let proposal = Web3Wallet.instance
            .sessionProposalPublisher
            .flatMapLatest { [app, publicKeyProvider, enabledCurrenciesService] proposal -> AnyPublisher<WalletConnectProposalResult, Never> in
                let networks = networks(from: proposal, enabledCurrenciesService: enabledCurrenciesService)
                if networks.unsupported.isNotEmpty {
                    return .just(
                        .failure(
                            message: WalletConnectServiceError.unknownNetwork.errorDescription,
                            metadata: proposal.proposer
                        )
                    )
                }
                // we only support one ETH wallet at the moment
                return publicKeyProvider.publicKey(network: .ethereum)
                    .map { address in
                        .request(
                            WalletConnectProposal(
                                proposal: proposal,
                                account: address,
                                networks: networks.supported
                            )
                        )
                    }
                    .ignoreFailure(redirectsErrorTo: app)
                    .eraseToAnyPublisher()
            }
            .map { [app] result -> SessionV2Event in
                switch result {
                case .request(let proposal):
                    app.state.set(blockchain.ux.wallet.connect.pair.request.proposal, to: proposal)
                    return .pairRequest(proposal)
                case .failure(let message, let appMetadata):
                    return .failure(message, appMetadata)
                }
            }
            .eraseToAnyPublisher()

        Publishers.Merge(proposal, settled)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: _sessionEvents.send)
            .store(in: &bag)

        Web3Wallet.instance
            .sessionRequestPublisher
            .flatMapLatest { [weak self, accountProvider] request -> AnyPublisher<WalletConnectUserEvent, Never> in
                guard let self else {
                    return .just(.failure(message: WalletConnectServiceError.unknown.localizedDescription, metadata: nil))
                }
                let peerMetadata = self.session(from: request.topic)?.peer
                guard let method = WalletConnectSupportedMethods(rawValue: request.method) else {
                    return .just(.failure(message: WalletConnectServiceError.unsupportedMethod.localizedDescription, metadata: peerMetadata))
                }
                guard let network = self.getNetwork(from: request.chainId) else {
                    return .just(.failure(message: WalletConnectServiceError.unknownNetwork.localizedDescription, metadata: peerMetadata))
                }
                return accountProvider
                    .defaultAccount(network: network)
                    .eraseError()
                    .flatMapLatest { account -> AnyPublisher<WalletConnectUserEvent, Error> in
                        self.createTxTarget(from: request, network: network)
                            .map { txTarget in
                                self.createUserEvent(from: method, account: account, txTarget: txTarget)
                            }
                            .eraseToAnyPublisher()
                    }
                    .catch { [app] error -> WalletConnectUserEvent in
                        app.post(error: error)
                        return .failure(
                            message: error.localizedDescription,
                            metadata: peerMetadata
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: _userEvents.send)
            .store(in: &bag)
    }

    func pair(uri: WalletConnectURI) async throws {
        try await Web3Wallet.instance.pair(uri: uri)
    }

    func disconnect(topic: String) async throws {
        try await Web3Wallet.instance.disconnect(topic: topic)
    }

    func approve(proposal: WalletConnectSign.Session.Proposal) async throws {
        let blockchains = proposal.requiredNamespaces.flatMap { namespace -> [Blockchain] in
            Array(namespace.value.chains ?? []).compactMap { blockchain -> Blockchain? in
                guard isSupportedChain(id: blockchain.reference) else {
                    print("Unsupported Chain Id: \(blockchain) on \(proposal)")
                    return nil
                }
                return blockchain
            }
        }
        let accounts = try await accounts(from: blockchains)
        let namespaces = try AutoNamespaces.build(
            sessionProposal: proposal,
            chains: blockchains,
            methods: Array(WalletConnectSupportedMethods.allMethods),
            events: ["accountsChanged", "chainChanged"],
            accounts: accounts
        )
        try await Web3Wallet.instance.approve(proposalId: proposal.id, namespaces: namespaces)
    }

    func reject(proposal: WalletConnectSign.Session.Proposal) async throws {
        try await Web3Wallet.instance.reject(proposalId: proposal.id, reason: .userRejected)
    }

    func cleanup() {
        Task(priority: .high) {
            try await Web3Wallet.instance.cleanup()
        }
    }

    // MARK: Request methods

    func sign(request: WalletConnectSign.Request, response: RPCResult) async throws {
        try await Web3Wallet.instance.respond(topic: request.topic, requestId: request.id, response: response)
    }

    func createUserEvent(
        from method: WalletConnectSupportedMethods,
        account: SingleAccount,
        txTarget: any TransactionTarget
    ) -> WalletConnectUserEvent {
        switch method {
        case .ethSendTransaction:
            return .sendTransaction(account, txTarget)
        case .ethSignTransaction:
            return .signTransaction(account, txTarget)
        case .ethSign,
                .ethSignTypedData,
                .personalSign:
            return .signMessage(account, txTarget)
        }
    }

    func createTxTarget(from request: WalletConnectSign.Request, network: EVMNetwork) -> AnyPublisher<any TransactionTarget, Error> {
        guard let session = session(from: request.topic) else {
            return .failure(WalletConnectServiceError.missingSession)
        }
        let txRejected: () -> AnyPublisher<Void, Never> = { [weak self, app] in
            Task.Publisher { [weak self] in
                try await self?.sign(request: request, response: .error(.userRejected))
            }
            .catch { [app] error -> AnyPublisher<Void, Never> in
                app.post(error: error)
                return .just(())
            }
            .eraseToAnyPublisher()
        }
        let txCompleted: TransactionTarget.TxCompleted = { [weak self] result in
            Task.Publisher { [weak self] in
                switch result {
                case .signed(let string):
                    try await self?.sign(request: request, response: .response(AnyCodable(string)))
                case .hashed(let txHash, _):
                    try await self?.sign(request: request, response: .response(AnyCodable(txHash)))
                case .unHashed:
                    throw WalletConnectServiceError.invalidTxCompletion
                }
            }
            .eraseToAnyPublisher()
        }
        guard let target = txTarget(request, session: session, network: network, txCompleted: txCompleted, txRejected: txRejected) else {
            return .failure(WalletConnectServiceError.invalidTxTarget)
        }
        return .just(target)
    }

    // MARK: - Private

    func session(from topic: String) -> SessionV2? {
        Web3Wallet.instance.getSessions().first(where: { $0.topic == topic })
    }

    func accounts(from chains: [Blockchain]) async throws -> [WalletConnectSign.Account] {
        var accounts: [WalletConnectSign.Account] = []
        for blockchain in chains {
            guard let network = network(enabledCurrenciesService: enabledCurrenciesService, chainID: blockchain.reference) else {
                continue
            }
            let address = try await address(from: network)
            if let account = WalletConnectSign.Account(blockchain: blockchain, address: address) {
                accounts.append(account)
            }
        }
        return accounts
    }

    func address(from network: EVMNetwork) async throws -> String {
        try await publicKeyProvider.publicKey(network: network).receive(on: DispatchQueue.main).await()
    }

    /// `true` if the chain id of a network is supported
    func isSupportedChain(id: String) -> Bool {
        network(enabledCurrenciesService: enabledCurrenciesService, chainID: id) != nil
    }

    func getNetwork(from blockchain: Blockchain) -> EVMNetwork? {
        network(enabledCurrenciesService: enabledCurrenciesService, chainID: blockchain.reference)
    }
}

// MARK: - Private Methods

/// Returns a tuple of the supported network(s) and any unsupported network(s) based on the given Wallet Connect Proposal
private func networks(
    from proposal: SessionV2.Proposal,
    enabledCurrenciesService: EnabledCurrenciesServiceAPI
) -> (supported: [EVMNetwork], unsupported: [Blockchain]) {
    var supported: [EVMNetwork] = []
    var unsuported: [Blockchain] = []
    for value in proposal.requiredNamespaces.values {
        let chains = value.chains ?? []
        for chain in chains {
            guard let network = network(enabledCurrenciesService: enabledCurrenciesService, chainID: chain.reference) else {
                unsuported.append(chain)
                continue
            }
            supported.append(network)
        }
    }
    return (supported, unsuported)
}

/// Retrieves the network based on the given chain id
private func network(enabledCurrenciesService: EnabledCurrenciesServiceAPI, chainID: String) -> EVMNetwork? {
    enabledCurrenciesService
        .allEnabledEVMNetworks
        .first(where: { network in
            network.networkConfig.chainID == BigUInt(chainID)
        })
}

extension JSONRPCError {
    static let userRejected = JSONRPCError(code: -32500, message: "User cancelled the request")
}
