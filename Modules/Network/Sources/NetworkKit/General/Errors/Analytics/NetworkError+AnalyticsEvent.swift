// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Errors
import Foundation

extension NetworkError {

    func analyticsEvent(
        for request: NetworkRequest,
        decodeErrorResponse: ((ServerErrorResponse) -> String?)? = nil
    ) -> AnalyticsEvent? {
        switch type {
        case .urlError(let urlError):
            return NetworkErrorEvent(request: request, error: urlError)
        case .rawServerError, .serverError, .payloadError, .authentication:
            return APIErrorEvent(
                request: request,
                error: self,
                decodeErrorResponse: decodeErrorResponse
            )
        }
    }
}
