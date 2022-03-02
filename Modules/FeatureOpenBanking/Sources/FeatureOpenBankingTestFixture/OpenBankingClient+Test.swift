// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Combine
import CombineSchedulers
@testable import FeatureOpenBankingData
@testable import FeatureOpenBankingDomain
import FirebaseProtocol
import Foundation
@testable import NetworkKit

extension OpenBanking {

    public static func test<S: Scheduler>(
        app: AppProtocol,
        requests: [URLRequest: Data] = [:],
        using scheduler: S
    ) -> (banking: OpenBanking, network: ReplayNetworkCommunicator) where
        S.SchedulerTimeType == DispatchQueue.SchedulerTimeType,
        S.SchedulerOptions == DispatchQueue.SchedulerOptions
    {
        let (banking, network) = OpenBankingClient.test(app: app, using: scheduler)
        return (
            OpenBanking(app: app, banking: banking),
            network
        )
    }
}

extension OpenBankingClient {

    public static func test(
        app: AppProtocol,
        requests: [URLRequest: Data] = [:]
    ) -> (
        banking: OpenBankingClient,
        communicator: ReplayNetworkCommunicator
    ) {
        test(app: app, requests: requests, using: DispatchQueue.immediate)
    }

    public static func test<S: Scheduler>(
        app: AppProtocol,
        requests: [URLRequest: Data] = [:],
        using scheduler: S
    ) -> (
        banking: OpenBankingClient,
        communicator: ReplayNetworkCommunicator
    ) where
        S.SchedulerTimeType == DispatchQueue.SchedulerTimeType,
        S.SchedulerOptions == DispatchQueue.SchedulerOptions
    {
        let communicator = ReplayNetworkCommunicator(requests, in: Bundle.module)
        return (
            OpenBankingClient(
                app: app,
                requestBuilder: RequestBuilder(
                    config: Network.Config(
                        scheme: "https",
                        host: "api.blockchain.info",
                        components: ["nabu-gateway"]
                    ),
                    headers: [
                        "Authorization": "Bearer Token"
                    ]
                ),
                network: NetworkAdapter(
                    communicator: communicator
                ).network,
                scheduler: scheduler.eraseToAnyScheduler()
            ),
            communicator
        )
    }
}

extension Array where Element == NetworkRequest {

    public subscript(method: NetworkRequest.NetworkMethod, url: URL) -> NetworkRequest? {
        first(where: { $0.method == method && $0.urlRequest.url == url })
    }
}

extension URLRequest {

    public init(_ method: NetworkRequest.NetworkMethod, _ url: URL, _ contentType: NetworkRequest.ContentType = .json) {
        self.init(url: url)
        httpMethod = method.rawValue
        addValue(contentType.rawValue, forHTTPHeaderField: "Accept")
    }
}
