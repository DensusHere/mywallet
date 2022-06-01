// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors

protocol CustodialQuoteAPI {

    func fetchQuoteResponse(
        with request: OrderQuoteRequest
    ) -> AnyPublisher<OrderQuoteResponse, NabuNetworkError>
}
