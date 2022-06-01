// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors

protocol CardOrderConfirmationClientAPI: AnyObject {

    /// Confirm an order
    func confirmOrder(
        with identifier: String,
        partner: OrderPayload.ConfirmOrder.Partner,
        paymentMethodId: String?
    ) -> AnyPublisher<OrderPayload.Response, NabuNetworkError>
}
