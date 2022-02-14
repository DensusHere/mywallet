// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import WalletPayloadKit

struct OptionsResponse: Equatable, Codable {
    let pbkdf2Iterations: Int
    let feePerKB: Int
    let html5Notifications: Bool
    let logoutTime: Int

    enum CodingKeys: String, CodingKey {
        case pbkdf2Iterations = "pbkdf2_iterations"
        case feePerKB = "fee_per_kb"
        case html5Notifications = "html5_notifications"
        case logoutTime = "logout_time"
    }
}

extension WalletPayloadKit.Options {
    static func from(model: OptionsResponse) -> Options {
        Options(
            pbkdf2Iterations: model.pbkdf2Iterations,
            feePerKB: model.feePerKB,
            html5Notifications: model.html5Notifications,
            logoutTime: model.logoutTime
        )
    }

    var toOptionsReponse: OptionsResponse {
        OptionsResponse(
            pbkdf2Iterations: pbkdf2Iterations,
            feePerKB: feePerKB,
            html5Notifications: html5Notifications,
            logoutTime: logoutTime
        )
    }
}
