// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import DIKit
import EthereumKit
import FeatureWalletConnectDomain
import MoneyKit
import WalletConnectSwift

final class SwitchRequestHandler: RequestHandler {

    private enum Method: String {
        case sendRawTransaction = "wallet_switchEthereumChain"
    }

    private let enabledCurrenciesService: EnabledCurrenciesServiceAPI
    private let getSession: (WCURL) -> Session?
    private let responseEvent: (WalletConnectResponseEvent) -> Void
    private let sessionEvent: (WalletConnectSessionEvent) -> Void

    init(
        enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve(),
        getSession: @escaping (WCURL) -> Session?,
        responseEvent: @escaping (WalletConnectResponseEvent) -> Void,
        sessionEvent: @escaping (WalletConnectSessionEvent) -> Void
    ) {
        self.enabledCurrenciesService = enabledCurrenciesService
        self.getSession = getSession
        self.responseEvent = responseEvent
        self.sessionEvent = sessionEvent
    }

    func canHandle(request: Request) -> Bool {
        Method(rawValue: request.method) != nil
    }

    func handle(request: Request) {
        guard let session = getSession(request.url) else {
            responseEvent(.invalid(request))
            return
        }
        guard let payload = try? request.parameter(of: ChainIdPayload.self, at: 0) else {
            // Invalid Payload.
            responseEvent(.invalid(request))
            return
        }
        guard let chainID = BigUInt(payload.chainId.withoutHex, radix: 16) else {
            // Invalid value.
            responseEvent(.invalid(request))
            return
        }
        guard let network: EVMNetwork = EVMNetwork(chainID: chainID) else {
            // Chain not recognised.
            responseEvent(.invalid(request))
            return
        }
        guard enabledCurrenciesService.allEnabledCryptoCurrencies.contains(network.cryptoCurrency) else {
            // Chain recognised, but currently disabled.
            responseEvent(.invalid(request))
            return
        }

        sessionEvent(.shouldChangeChainID(session, request, network))
    }
}

private struct ChainIdPayload: Decodable {
    let chainId: String
}
