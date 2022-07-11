// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

extension Tag {

    public var reference: Tag.Reference { ref() }

    public func ref(to indices: Tag.Context = [:], in app: AppProtocol? = nil) -> Tag.Reference {
        Tag.Reference(self, to: indices, in: app)
    }
}

extension Tag.Reference {

    public func `in`(_ app: AppProtocol) -> Tag.Reference {
        if ObjectIdentifier(app) == self.app { return self }
        return Tag.Reference(tag, to: context, in: app)
    }

    public func ref(to indices: Tag.Context = [:], in app: AppProtocol? = nil) -> Tag.Reference {
        Tag.Reference(tag, to: context + indices, in: app)
    }
}

extension Tag {

    public struct Reference {

        public typealias Indices = [Tag: String]

        public let tag: Tag

        public let indices: Indices
        public let context: Context

        public let string: String

        private var error: Swift.Error?
        private var app: ObjectIdentifier?

        @usableFromInline init(_ tag: Tag, to context: Tag.Context, in app: AppProtocol? = nil) {
            do {
                self = try Self(checked: tag, context: context, in: app)
            } catch {
                self = Self(unchecked: tag, context: context)
                self.error = error
            }
        }

        @usableFromInline init(unchecked tag: Tag, context: Tag.Context) {
            self.tag = tag
            self.context = context
            indices = [:]
            string = tag.id
            error = tag.template.indices.set.subtracting(Self.volatileIndices.map(\.id)).isNotEmpty
                ? tag.error(message: "Missing indices for ref to \(tag.id)")
                : nil
        }

        @usableFromInline init(checked tag: Tag, context: Tag.Context, in app: AppProtocol? = nil) throws {
            self.tag = tag
            self.context = context
            let ids = try tag.template.indices(from: context, in: app)
            let indices = try Dictionary(
                uniqueKeysWithValues: zip(
                    tag.template.indices.map { try Tag(id: $0, in: tag.language) },
                    ids
                )
            )
            self.app = app.map(ObjectIdentifier.init)
            self.indices = indices
            string = Self.id(
                tag: tag,
                to: indices
            )
        }
    }
}

extension Tag.Reference {

    public var hasError: Bool { error != nil }

    @discardableResult
    public func validated() throws -> Tag.Reference {
        guard let error = error else { return self }
        throw error
    }
}

extension Tag.Reference {

    // swiftlint:disable:next force_try
    public static let pattern = try! NSRegularExpression(pattern: #"\.(?<name>[\w_]+)(?:\[(?<id>[^\.]+)\])?"#)

    public init(id: String, in language: Language) throws {

        var tag = blockchain[]
        var indices: [Tag: String] = [:]

        for match in Tag.Reference.pattern.matches(in: id, range: NSRange(id.startIndex..<id.endIndex, in: id)) {

            let range = (
                name: match.range(withName: "name"),
                id: match.range(withName: "id")
            )

            tag = try tag.child(named: id[range.name].string)
            guard range.id.location != NSNotFound else { continue }
            try indices[
                tag.child(named: blockchain.db.collection.id[].name)
            ] = id[range.id].string
        }
        self.init(tag, to: Tag.Context(indices), in: nil)
    }
}

extension Tag.Reference {

    public static let volatileIndices: Set<Tag> = [
        blockchain.user.id[]
    ]

    public func id(ignoring: Set<Tag> = Tag.Reference.volatileIndices) -> String {
        Self.id(
            tag: tag,
            to: indices,
            ignoring: ignoring
        )
    }

    fileprivate static func id(
        tag: Tag,
        to indices: Indices,
        ignoring: Set<Tag> = Tag.Reference.volatileIndices
    ) -> String {
        var ignoring = ignoring
        if tag.is(blockchain.db.collection.id) {
            ignoring.insert(tag)
        }
        guard indices.keys.count(where: ignoring.doesNotContain) > 0 else {
            return tag.id
        }
        return tag.lineage
            .reversed()
            .map { info in
                guard
                    let collectionId = info["id"],
                    ignoring.doesNotContain(collectionId),
                    let id = indices[collectionId]
                else {
                    return info.name
                }
                return "\(info.name)[\(id)]"
            }
            .joined(separator: ".")
    }
}

extension Tag.Reference: Equatable {

    public static func == (lhs: Tag.Reference, rhs: Tag.Reference) -> Bool {
        lhs.string == rhs.string
    }

    public static func == (lhs: Tag.Reference, rhs: Tag) -> Bool {
        lhs.string == rhs.id
    }

    public static func == (lhs: Tag.Reference, rhs: L) -> Bool {
        lhs.string == rhs(\.id)
    }

    public static func != (lhs: Tag.Reference, rhs: Tag) -> Bool {
        !(lhs == rhs)
    }

    public static func != (lhs: Tag.Reference, rhs: L) -> Bool {
        !(lhs == rhs)
    }
}

extension Tag.Reference: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(string)
    }
}

extension Tag.Reference: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let language = decoder.userInfo[.language] as? Language ?? Language.root.language
        try self.init(id: container.decode(String.self), in: language)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(string)
    }
}

extension Tag.Reference {

    public struct Template {

        private let tagId: Tag.ID
        public private(set) var indices: [String] = []

        init(_ tag: Tag) {
            tagId = tag.id
            var id = ""
            for crumb in tag.breadcrumb {
                if crumb.name == crumb.id {
                    id = crumb.name
                    continue
                }
                id += ".\(crumb.name)"
                if crumb.is(blockchain.db.collection) {
                    indices.append(id + ".id")
                }
            }
        }

        func indices(from ids: Tag.Context, in app: AppProtocol?) throws -> [String] {
            let ids = ids.mapKeysAndValues(
                key: \.description,
                value: String.init(describing:)
            )
            return try indices.map { id in
                if let value = ids[id], value.isNotEmpty {
                    return value
                } else if tagId == id {
                    return "ø"
                } else if let tag = app?.language[id], let value = try? app?.state.get(tag, as: String.self) {
                    return value
                } else {
                    throw blockchain.db.type.tag[].error(message: "Missing index \(id) for ref to \(tagId)")
                }
            }
        }
    }
}

extension Tag.Reference: CustomStringConvertible {
    public var description: String { string }
}
