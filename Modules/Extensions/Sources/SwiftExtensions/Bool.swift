// Copyright © Blockchain Luxembourg S.A. All rights reserved.

infix operator &&=: AssignmentPrecedence

public func &&= (x: inout Bool, y: Bool) {
    x = x && y
}

extension Bool {
    public var not: Bool { !self }
}

extension Bool {

    @inlinable public static func && (lhs: Self, rhs: () async throws -> Self) async rethrows -> Self {
        guard lhs else { return false }
        return try await rhs()
    }

    @inlinable public static func || (lhs: Self, rhs: () async throws -> Self) async rethrows -> Self {
        if lhs { return true }
        return try await rhs()
    }
}
