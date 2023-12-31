// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Foundation
import SwiftUI

extension ActivityItem {
    public struct Button: Equatable, Codable, Hashable, Identifiable {
        public init(
            text: String,
            style: ActivityItem.ButtonStyle,
            actionType: ActivityItem.ButtonActionType,
            actionData: String
        ) {
            self.text = text
            self.style = style
            self.actionType = actionType
            self.actionData = actionData
        }

        public var id: String {
            "\(hashValue)"
        }

        public let text: String
        public let style: ButtonStyle
        public let actionType: ButtonActionType
        public let actionData: String

        public var action: L_blockchain_ui_type_action.JSON {
            var action = L_blockchain_ui_type_action.JSON(.empty)

            switch actionType {
            case .opneURl:
                action.then.launch.url = URL(string: actionData)
            case .copy:
                action.then.copy = actionData
            }

            return action
        }
    }

    public enum ButtonStyle: String, Equatable, Codable, Hashable {
        case primary
        case secondary
    }

    public enum ButtonActionType: String, Equatable, Codable, Hashable {
        case opneURl = "OPEN_URL"
        case copy = "COPY"
    }
}
