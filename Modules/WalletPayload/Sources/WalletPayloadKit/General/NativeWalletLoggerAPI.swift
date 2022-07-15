// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation
import ToolKit

public protocol NativeWalletLoggerAPI {
    func log(message: String, metadata: [String: String]?)
}

extension Publisher {
    func logMessageOnOutput(
        logger: NativeWalletLoggerAPI,
        messageAndMetadata: @escaping (Self.Output) -> (String, [String: String]?)
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(receiveOutput: { value in
            if BuildFlag.isInternal || BuildFlag.isAlpha {
                let (message, metadata) = messageAndMetadata(value)
                logger.log(message: message, metadata: metadata)
            }
        })
    }

    func logMessageOnOutput(
        logger: NativeWalletLoggerAPI,
        message: @escaping (Self.Output) -> String
    ) -> Publishers.HandleEvents<Self> {
        handleEvents(receiveOutput: { value in
            if BuildFlag.isInternal || BuildFlag.isAlpha {
                let message = message(value)
                logger.log(message: message, metadata: nil)
            }
        })
    }
}
