import Foundation
import Localization
import OrderedCollections

// swiftlint:disable type_name
public enum UX {

    public struct Error: Swift.Error {

        public typealias Metadata = OrderedDictionary<String, String>

        public var source: Swift.Error?
        public var title: String
        public var message: String
        public var expected: Bool = true
        public var icon: UX.Icon?
        public var metadata: Metadata
        public var actions: [Action]

        public init(
            source: Swift.Error? = nil,
            title: String,
            message: String,
            icon: UX.Icon? = nil,
            metadata: Metadata = [:],
            actions: [UX.Action] = .default
        ) {
            self.source = source
            self.title = title
            self.message = message
            self.icon = icon
            self.metadata = metadata
            self.actions = actions
        }

        public init(
            source: Swift.Error? = nil,
            title: String?,
            message: String?,
            icon: UX.Icon? = nil,
            metadata: Metadata = [:],
            actions: [UX.Action] = .default
        ) {
            self.source = source
            self.title = title ?? L10n.oops.title
            self.message = message ?? L10n.oops.message
            self.icon = icon
            self.metadata = metadata
            self.actions = actions
            expected = title != nil
        }
    }
}

extension UX.Error: Equatable {

    public static func == (lhs: UX.Error, rhs: UX.Error) -> Bool {
        lhs.title == rhs.title
            && lhs.message == rhs.message
            && lhs.icon == rhs.icon
            && lhs.metadata == rhs.metadata
            && lhs.actions == rhs.actions
            && String(describing: lhs.source) == String(describing: rhs.source)
    }
}

extension UX.Error: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(message)
        hasher.combine(icon)
        hasher.combine(metadata)
        hasher.combine(actions)
    }
}

typealias L10n = LocalizationConstants.UX.Error

extension UX.Error {

    public init(nabu: Nabu.Error) {

        var metadata: Metadata = [:]

        source = nabu

        if let ux = nabu.ux {
            title = ux.title
            message = ux.message
            icon = ux.icon
            actions = ux.actions ?? []
        } else {
            title = L10n.networkError.title
            message = nabu.description ?? L10n.oops.message
            icon = nil
            actions = .default
            expected = false
        }

        if let request = nabu.request {
            if let id = request.allHTTPHeaderFields?["X-Request-ID"] {
                metadata[L10n.request] = id
            }
            if let id = request.allHTTPHeaderFields?["X-Session-ID"] {
                metadata[L10n.session] = id
            }
        }

        self.metadata = metadata
    }

    public init(nabu ux: Nabu.Error.UX) {
        source = nil
        title = ux.title
        message = ux.message
        icon = ux.icon
        actions = ux.actions ?? .default
        metadata = [:]
    }
}

extension UX.Error {

    public init(error: Swift.Error?) {
        switch error {
        case let nabu as Nabu.Error:
            self.init(nabu: nabu)
        default:
            self.init(
                source: error,
                title: L10n.oops.title,
                message: L10n.oops.message,
                icon: nil,
                metadata: [:],
                actions: .default
            )
            expected = false
        }
    }
}

extension Array where Element == UX.Action {

    public static var `default`: Self = [
        UX.Action(title: L10n.ok)
    ]
}
