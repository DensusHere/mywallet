// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureCryptoDomainDomain
import Foundation

public final class OrderDomainRepository: OrderDomainRepositoryAPI {

    // MARK: - Properties

    private let apiClient: OrderDomainClientAPI

    // MARK: - Setup

    public init(apiClient: OrderDomainClientAPI) {
        self.apiClient = apiClient
    }

    public func createDomainOrder(
        isFree: Bool,
        domainName: String,
        resolutionRecords: [ResolutionRecord]?
    ) -> AnyPublisher<OrderDomainResult, OrderDomainRepositoryError> {
        apiClient
            .postOrder(
                payload: PostOrderRequest(
                    domainCampaign: "UNSTOPPABLE_DOMAINS",
                    domain: domainName,
                    owner: resolutionRecords?.first?.walletAddress ?? "",
                    records: resolutionRecords?.map(Record.init) ?? [],
                    isFree: isFree
                )
            )
            .map { response in
                if response.isFree {
                    return OrderDomainResult(
                        domainType: .free,
                        orderNumber: Int(response.order?.orderNumber ?? "0"),
                        redirectUrl: nil
                    )
                } else {
                    return OrderDomainResult(
                        domainType: .premium,
                        orderNumber: nil,
                        redirectUrl: response.redirectUrl ?? ""
                    )
                }
            }
            .mapError(OrderDomainRepositoryError.networkError)
            .eraseToAnyPublisher()
    }
}
