// Copyright © Blockchain Luxembourg S.A. All rights reserved.

extension AsyncSequence {

    @discardableResult
    public func next() async throws -> Element? {
        for try await o in self {
            return o
        }
        return nil
    }
}
