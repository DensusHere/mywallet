// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

extension ActivityItem {
    public struct Badge: Equatable, Decodable {
        public let value: String
        public let style: String // blueBadge
    }
}
