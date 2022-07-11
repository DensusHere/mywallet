// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors
import Foundation

public protocol TransactionServiceAPI {

    func fetchTransactions() -> AnyPublisher<[Card.Transaction], NabuNetworkError>

    func fetchMore() -> AnyPublisher<[Card.Transaction], NabuNetworkError>
}
