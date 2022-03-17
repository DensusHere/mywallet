// https://github.com/ollieatkinson/Eumorphic/blob/anything/Sources/Anything/AnyDecoder.swift

import Combine
import CoreGraphics
import Foundation

public protocol AnyDecoderProtocol: AnyObject, Decoder {

    var value: Any { get set }
    var codingPath: [CodingKey] { get set }

    init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any])

    func decode<T>(_: T.Type, from any: Any) throws -> T where T: Decodable
    func convert<T>(_ any: Any, to: T.Type) throws -> Any?
}

open class AnyDecoder: AnyDecoderProtocol {

    public var codingPath: [CodingKey] = []
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    public var value: Any = NSNull()

    public required init(codingPath: [CodingKey] = [], userInfo: [CodingUserInfoKey: Any] = [:]) {
        self.codingPath = codingPath
        self.userInfo = userInfo
    }

    public func decode<T>(_: T.Type = T.self, from any: Any) throws -> T where T: Decodable {
        let old = value
        value = any
        defer { value = old }
        do {
            if let o = T.self as? OptionalDecodableProtocol.Type {
                return o.decodeUnwrapped(from: self) as! T
            }
            if let optional = any as? OptionalProtocol {
                guard let value = optional.flattened else { throw valueNotFound(T.self, at: codingPath) }
                return try decode(T.self, from: value)
            } else if let o = try convert(any, to: T.self) as? T {
                return o
            }
            return try T(from: self)
        } catch {
            return try any as? T ?? ((T.self as? OptionalProtocol.Type)?.null as? T).or(throw: error)
        }
    }

    public func decode<T>(_: T?.Type = T?.self, from any: Any) -> T? where T: Decodable {
        try? decode(T.self, from: any)
    }

    open func convert<T>(_ any: Any, to type: T.Type) throws -> Any? {
        switch (any, T.self) {
        case (let time as TimeInterval, is Date.Type):
            return Date(timeIntervalSince1970: time)
        case (let string as String, is URL.Type):
            return try URL(string: string).or(throw: Error(message: "'\(string)' is not a URL", at: codingPath))
        case (let number as NSNumber, is Bool.Type):
            return number.boolValue
        case (let number as NSNumber, is Int.Type):
            return number.intValue
        case (let number as NSNumber, is UInt.Type):
            return number.uintValue
        case (let number as NSNumber, is Float.Type):
            return number.floatValue
        case (let number as NSNumber, is Double.Type):
            return number.doubleValue
        case (let number as NSNumber, is CGFloat.Type):
            return number.doubleValue
        default:
            return nil
        }
    }
}

extension AnyDecoder {

    public struct Error: Swift.Error, LocalizedError {

        public let message: String
        public let codingPath: [CodingKey]

        public init(
            message: String,
            at codingPath: [CodingKey]
        ) {
            self.message = message
            self.codingPath = codingPath
        }

        public var errorDescription: String? { message }
    }

    // swiftlint:disable line_length
    func valueNotFound<T>(
        _: T.Type,
        at codingPath: [CodingKey]
    ) -> Error {
        .init(
            message: "Value of type \(T.self) not found at coding path /\(codingPath.string); found \(Swift.type(of: value))",
            at: codingPath
        )
    }
}

extension AnyDecoder {

    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        try KeyedDecodingContainer(KeyedContainer<Key>(decoder: self))
    }

    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        try UnkeyedContainer(decoder: self)
    }

    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        try SingleValueContainer(decoder: self)
    }
}

extension AnyDecoder {

    public struct KeyedContainer<Key> where Key: CodingKey {

        let decoder: AnyDecoder
        public let dictionary: [String: Any]

        public var codingPath: [CodingKey] { decoder.codingPath }
        public var userInfo: [CodingUserInfoKey: Any] { decoder.userInfo }

        public init(decoder: AnyDecoder) throws {
            self.decoder = decoder
            dictionary = try (decoder.value as? [String: Any])
                .or(throw: Error(message: "Expected a [String: Any] but got: \(decoder.value)", at: decoder.codingPath))
        }

        public func value(for key: Key) throws -> Any {
            try dictionary[key.stringValue]
                .or(throw: Error(message: "No value found for key '\(key.stringValue)'", at: codingPath))
        }
    }
}

extension AnyDecoder.KeyedContainer: KeyedDecodingContainerProtocol {

    public var allKeys: [Key] {
        dictionary.keys.compactMap(Key.init)
    }

    public func contains(_ key: Key) -> Bool {
        dictionary[key.stringValue] != nil
    }

    public func decodeNil(forKey key: Key) throws -> Bool {
        isNil(dictionary[key.stringValue])
    }

    public func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        let value = try value(for: key)
        decoder.codingPath.append(AnyCodingKey(key.stringValue))
        defer { decoder.codingPath.removeLast() }
        return try decoder.decode(from: value)
    }
}

extension AnyDecoder {

    public struct SingleValueContainer {

        public let decoder: AnyDecoder
        public let value: Any

        public var codingPath: [CodingKey] { decoder.codingPath }
        public var userInfo: [CodingUserInfoKey: Any] { decoder.userInfo }

        public init(decoder: AnyDecoder) throws {
            self.decoder = decoder
            value = decoder.value
        }
    }
}

extension AnyDecoder.SingleValueContainer: SingleValueDecodingContainer {

    public func decodeNil() -> Bool {
        isNil(value)
    }

    public func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        guard type.containerType == .singleValue else {
            return try decoder.decode(from: value)
        }
        return try (value as? T).or(throw: decoder.valueNotFound(T.self, at: codingPath))
    }
}

extension AnyDecoder {

    public struct UnkeyedContainer {

        public let array: [Any]
        public let decoder: AnyDecoder

        public var count: Int? { array.count }
        public private(set) var currentIndex: Int = 0

        public var codingPath: [CodingKey] { decoder.codingPath }
        public var userInfo: [CodingUserInfoKey: Any] { decoder.userInfo }

        public init(decoder: AnyDecoder) throws {
            self.decoder = decoder
            array = try (decoder.value as? [Any])
                .or(throw: Error(message: "Expected a [Any] but got: \(decoder.value)", at: decoder.codingPath))
        }
    }
}

extension AnyDecoder.UnkeyedContainer: UnkeyedDecodingContainer {

    public var isAtEnd: Bool { currentIndex == count }

    public mutating func decodeNil() throws -> Bool {
        let null = isNil(array[currentIndex])
        defer { currentIndex += null ? 1 : 0 }
        return null
    }

    public mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        defer { currentIndex += 1 }
        decoder.codingPath.append(AnyCodingKey(currentIndex))
        defer { decoder.codingPath.removeLast() }
        return try decoder.decode(from: array[currentIndex])
    }
}

private func unsupported(_ function: String = #function) -> Never {
    fatalError("\(function) isn't supported by AnyDecoder")
}

extension AnyDecoder.KeyedContainer {
    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer { unsupported() }
    public func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey { unsupported() }
    public func superDecoder() throws -> Decoder { unsupported() }
    public func superDecoder(forKey key: Key) throws -> Decoder { unsupported() }
}

extension AnyDecoder.UnkeyedContainer {
    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer { unsupported() }
    public mutating func nestedContainer<NestedKey>(
        keyedBy type: NestedKey.Type
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey { unsupported() }
    public mutating func superDecoder() throws -> Decoder { unsupported() }
}

extension Sequence where Element == CodingKey {
    var string: String {
        map(\.stringValue).joined(separator: "/")
    }
}

private protocol OptionalDecodableProtocol: OptionalProtocol, Decodable {
    static func decodeUnwrapped<D: AnyDecoderProtocol>(from decoder: D) -> Self
}

extension Optional: OptionalDecodableProtocol where Wrapped: Decodable & Equatable {
    static func decodeUnwrapped<D: AnyDecoderProtocol>(from decoder: D) -> Optional {
        try? decoder.decode(Wrapped.self, from: decoder.value)
    }
}
