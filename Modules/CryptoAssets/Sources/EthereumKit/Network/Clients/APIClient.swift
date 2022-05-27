// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import NetworkKit
import PlatformKit

protocol TransactionPushClientAPI: AnyObject {

    /// Pushes a Ethereum transaction.
    func push(
        transaction: EthereumTransactionEncoded
    ) -> AnyPublisher<EthereumPushTxResponse, NetworkError>

    /// Pushes a EVM transaction
    func evmPush(
        transaction: EthereumTransactionEncoded,
        network: EVMNetwork
    ) -> AnyPublisher<EVMPushTxResponse, NetworkError>
}

protocol TransactionFeeClientAPI {

    func fees(
        cryptoCurrency: CryptoCurrency
    ) -> AnyPublisher<TransactionFeeResponse, NetworkError>
}

final class APIClient: TransactionPushClientAPI, TransactionFeeClientAPI {

    // MARK: - Types

    /// Privately used endpoint data
    private enum Endpoint {

        static func fees(network: EVMNetwork) -> String {
            switch network {
            case .ethereum:
                return "/mempool/fees/eth"
            case .polygon:
                return "/mempool/fees/matic"
            }
        }

        static var pushTx: String {
            "/eth/pushtx"
        }

        static var pushTxEVM: String {
            "/currency/evm/pushTx"
        }

        static func transactions(for address: String) -> String {
            "/v2/eth/data/account/\(address)/transactions"
        }

        static func transaction(with hash: String) -> String {
            "/v2/eth/data/transaction/\(hash)"
        }
    }

    // MARK: - Private Properties

    private let networkAdapter: NetworkAdapterAPI
    private let requestBuilder: RequestBuilder
    private let apiCode: String

    // MARK: - Setup

    init(
        networkAdapter: NetworkAdapterAPI = resolve(),
        requestBuilder: RequestBuilder = resolve(),
        apiCode: APICode = resolve()
    ) {
        self.networkAdapter = networkAdapter
        self.requestBuilder = requestBuilder
        self.apiCode = apiCode
    }

    func fees(
        cryptoCurrency: CryptoCurrency
    ) -> AnyPublisher<TransactionFeeResponse, NetworkError> {
        fees(
            contractAddress: cryptoCurrency.assetModel.kind.erc20ContractAddress,
            network: network(from: cryptoCurrency)
        )
    }

    private func network(from cryptoCurrency: CryptoCurrency) -> EVMNetwork {
        guard let network = cryptoCurrency.assetModel.evmNetwork else {
            let code = cryptoCurrency.code
            let chain = cryptoCurrency.assetModel.kind.erc20ParentChain?.rawValue ?? ""
            fatalError("Incompatible Asset: '\(code)', chain: '\(chain)'.")
        }
        return network
    }

    private func fees(
        contractAddress: String?,
        network: EVMNetwork
    ) -> AnyPublisher<TransactionFeeResponse, NetworkError> {
        var parameters: [URLQueryItem] = []
        if let contractAddress = contractAddress {
            parameters.append(URLQueryItem(name: "contractAddress", value: contractAddress))
        }
        let request = requestBuilder.get(
            path: Endpoint.fees(network: network),
            parameters: parameters
        )!
        return networkAdapter.perform(request: request)
    }

    func push(
        transaction: EthereumTransactionEncoded
    ) -> AnyPublisher<EthereumPushTxResponse, NetworkError> {
        let body = PushTxRequest(
            rawTx: transaction.rawTransaction,
            network: EVMNetwork.ethereum.rawValue,
            api_code: apiCode
        )
        let request = requestBuilder.post(
            path: Endpoint.pushTx,
            body: try? body.encode(),
            recordErrors: true
        )!
        return networkAdapter.perform(request: request)
    }

    func evmPush(
        transaction: EthereumTransactionEncoded,
        network: EVMNetwork
    ) -> AnyPublisher<EVMPushTxResponse, NetworkError> {
        let body = PushTxRequest(
            rawTx: transaction.rawTransaction,
            network: network.rawValue,
            api_code: apiCode
        )
        let request = requestBuilder.post(
            path: Endpoint.pushTxEVM,
            body: try? body.encode(),
            recordErrors: true
        )!
        return networkAdapter.perform(request: request)
    }
}
