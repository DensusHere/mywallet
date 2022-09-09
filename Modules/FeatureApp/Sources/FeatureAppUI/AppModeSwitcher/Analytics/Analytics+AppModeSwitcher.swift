// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import Foundation

extension AnalyticsEvents.New {
    enum AppModeSwitcher: AnalyticsEvent, Equatable {
        case switchedToDefi
        case switchedToTrading
        var type: AnalyticsEventType { .nabu }
    }
}
