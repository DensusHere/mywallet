// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine

/// Useful for injecting recorders
public protocol Recordable {
    func use(recorder: Recording)
}

/// Composition of all recording types
public typealias Recording = MessageRecording & ErrorRecording & UIOperationRecording

/// Can be used to record any `String` message
public protocol MessageRecording {
    func record(_ message: String)
}

/// Can be used to record any `Error` message
public protocol ErrorRecording {
    func error(_ error: Error)
}

/// Records any illegal UI operation
public protocol UIOperationRecording {
    func recordIllegalUIOperationIfNeeded()
}

extension Publisher {

    public func recordErrors(on recorder: ErrorRecording?) -> AnyPublisher<Output, Failure> {
        handleEvents(
            receiveCompletion: { completion in
                guard case .failure(let error) = completion else {
                    return
                }
                recorder?.error(error)
            }
        )
        .eraseToAnyPublisher()
    }

    public func recordErrors(on recorder: ErrorRecording?, enabled: Bool) -> AnyPublisher<Output, Failure> {
        guard enabled else {
            return eraseToAnyPublisher()
        }
        return recordErrors(on: recorder)
    }
}
