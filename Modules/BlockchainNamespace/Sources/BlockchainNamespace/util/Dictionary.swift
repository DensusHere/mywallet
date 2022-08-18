// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import SwiftExtensions

extension Dictionary where Key == Tag {
    public subscript(id: L) -> Value? { self[id[]] }
}

extension Dictionary where Key == Tag.Reference {
    public subscript(id: L) -> Value? { self[id.key()] }
}

extension Mock {

    public class Preferences: SwiftExtensions.Preferences {

        var store: [String: Any] = [:]

        public init() {}

        public func object(forKey defaultName: String) -> Any? {
            store[defaultName]
        }

        public func set(_ value: Any?, forKey defaultName: String) {
            store[defaultName] = value
        }
    }
}
