// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import UnifiedActivityDomain

public protocol CustodialActivityServiceAPI {
    func getActivity() async -> [ActivityEntry]
}
