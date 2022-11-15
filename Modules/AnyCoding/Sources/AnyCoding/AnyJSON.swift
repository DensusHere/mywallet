import Foundation
import SwiftExtensions

@dynamicMemberLookup
public struct AnyJSON: Codable, Hashable, Equatable, CustomStringConvertible {

    public struct Error: Swift.Error, CustomStringConvertible {
        public let description: String
    }

    public private(set) var wrapped: Any
    public var thing: Any { wrapped }
    public var any: Any { wrapped }

    internal var __unwrapped: Any {
        (wrapped as? AnyJSON)?.__unwrapped ?? wrapped
    }

    public init() {
        self = nil
    }

    public init(_ any: Any) {
        switch any {
        case let thing as AnyJSON:
            self = thing
        default:
            wrapped = any
        }
    }

    private var __subscript: Any? {
        get { wrapped }
        set { wrapped = newValue ?? NSNull() }
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Any?, T>) -> T? {
        __subscript[keyPath: keyPath]
    }

    public subscript(first: AnyCodingKey, rest: AnyCodingKey...) -> Any? {
        get { __subscript[[first] + rest] }
        set { __subscript[[first] + rest] = newValue }
    }

    public subscript(path: some Collection<CodingKey>) -> Any? {
        get { __subscript[path] }
        set { __subscript[path] = newValue }
    }

    public func hash(into hasher: inout Hasher) {
        (wrapped as? AnyHashable).hash(into: &hasher)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        if let lhs = lhs.__unwrapped as? AnyEquatable {
            return isEqual(lhs, rhs.__unwrapped as? AnyEquatable as Any)
        } else {
            return isEqual(lhs.__unwrapped, rhs.__unwrapped)
        }
    }

    public init(from decoder: Decoder) throws {
        switch decoder {
        case let decoder as AnyDecoderProtocol:
            func ƒ(_ any: Any) throws -> Any {
                switch try decoder.convert(any, to: Any.self) ?? any {
                case let array as [Any]:
                    return try array.enumerated().map { o -> Any in
                        decoder.codingPath.append(AnyCodingKey(o.offset))
                        defer { decoder.codingPath.removeLast() }
                        return try ƒ(o.element)
                    }
                case let dictionary as [String: Any]:
                    return try Dictionary(uniqueKeysWithValues: dictionary.map { o -> (String, Any) in
                        decoder.codingPath.append(AnyCodingKey(o.key))
                        defer { decoder.codingPath.removeLast() }
                        return try (o.key, ƒ(o.value))
                    })
                case let fragment:
                    return fragment
                }
            }
            self = try .init(ƒ(decoder.value))
        default:
            throw Error(
                description: """
                AnyJSON can only be decoded with
                AnyDecoderProtocol; got: \(decoder)
                """
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch encoder {
        case let encoder as AnyEncoderProtocol:
            func ƒ(_ any: Any) throws -> Any {
                if let o = try encoder.convert(any) { return o }
                switch any {
                case let array as [Any]:
                    return try array.map(ƒ)
                case let dictionary as [String: Any]:
                    return try dictionary.mapValues(ƒ)
                case let fragment:
                    return fragment
                }
            }
            encoder.value = try ƒ(wrapped)
        default:
            throw Error(
                description: """
                AnyJSON can currently only be encoded with a
                AnyEncoderProtocol; got: \(encoder)
                """
            )
        }
    }

    public func `as`<T>(_ type: T.Type) throws -> T {
        try (wrapped as? T).or(throw: Error(description: "Cannot cast \(Swift.type(of: wrapped)) to \(T.self)"))
    }

    public var description: String {
        String(describing: __unwrapped)
    }
}

extension AnyJSON: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.init(NSNull())
    }
}

extension AnyJSON: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }
}

extension AnyJSON: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Any)...) {
        self.init([String: Any].init(elements, uniquingKeysWith: { $1 }))
    }
}

extension AnyJSON: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}

extension AnyJSON: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension AnyJSON: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension AnyJSON: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self.init(value)
    }
}

extension AnyJSON: ExpressibleByStringInterpolation {
    public init(stringInterpolation: DefaultStringInterpolation) {
        self.init(stringInterpolation.description)
    }
}

extension AnyJSON: AnyEquatable {

    public static func isAnyEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        isEqual(
            (lhs as? AnyJSON)?.__unwrapped ?? lhs,
            (rhs as? AnyJSON)?.__unwrapped ?? rhs
        )
    }
}

extension AnyJSON {

    @_disfavoredOverload
    @inlinable public func decode<T: Decodable>(_: T.Type = T.self, using decoder: AnyDecoderProtocol) throws -> T {
        try decoder.decode(T.self, from: wrapped)
    }
}
