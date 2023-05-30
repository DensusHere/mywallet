extension Compute {

    public struct Exists: ComputeKeyword, Equatable {
        public let value: AnyJSON?
    }
}

extension Compute.Exists {

    public func compute() throws -> Any? {
        guard let value = value, value.isNotError else { return false }
        return true
    }
}

extension Compute.Exists: CustomStringConvertible {

    public var description: String {
        return "Exists(value: \(value ?? "nil"))"
    }
}
