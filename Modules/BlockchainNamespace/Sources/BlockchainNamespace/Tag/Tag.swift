// Copyright © Blockchain Luxembourg S.A. All rights reserved.
// swiftlint:disable type_name

import Foundation
import Lexicon

public struct Tag {

    public typealias Indices = [Tag: String]
    public typealias Context = [Tag: AnyHashable]

    public typealias ID = String
    public typealias Name = String

    public let id: ID
    public var name: Name { node.name }

    public let node: Lexicon.Graph.Node
    public unowned let language: Language

    public var parent: Tag? { parentID.flatMap(language.tag) }
    private let parentID: ID?

    public var protonym: Tag? { Tag.protonym(of: self) }
    public let ownChildren: [Name: Tag]
    public var children: [Name: Tag] { Tag.children(of: self) }
    public var ownType: [ID: Tag] { Tag.ownType(self) }
    public var type: [ID: Tag] { Tag.type(of: self) }
    public var lineage: UnfoldFirstSequence<Tag> { Tag.lineage(of: self) }

    init(parent: ID?, node: Lexicon.Graph.Node, in language: Language) {
        parentID = parent
        id = parent?.dot(node.name) ?? node.name
        self.node = node
        self.language = language
        var ownChildren: [Name: Tag] = [:]
        for (name, node) in node.children {
            ownChildren[name] = Tag.add(parent: id, node: node, to: language)
        }
        self.ownChildren = ownChildren
    }
}

extension L {
    public typealias Indices = [L: String]
    public typealias Context = [L: AnyHashable]
}

extension Tag {

    var isCollection: Bool { Tag.isCollection(self) }
    var isLeaf: Bool { Tag.isLeaf(self) }
    var isLeafDescendant: Bool { Tag.isLeafDescendant(self) }

    var template: Tag.Reference.Template { .init(self) }
    var breadcrumb: [Tag] { lineage.reversed().prefix(while: \.isLeafDescendant.not) }
}

extension Tag {

    public init(_ identifier: L, in language: Language) {
        do {
            self = try Tag(id: identifier(\.id), in: language)
        } catch {
            fatalError(
                """
                Failed to load language from identifier \(identifier(\.id))
                \(error)
                """
            )
        }
    }

    public init(id: String, in language: Language) throws {
        if id.isEmpty {
            self = blockchain.db.type.tag.none[]
        } else if let tag = language.tag(id) {
            self = tag
        } else {
            throw blockchain[].error(message: "'\(id)' does not exist in language")
        }
    }
}

extension L {
    public subscript() -> Tag { Tag(self, in: Language.root.language) }
}

extension Tag {

    public func `as`<T: L>(_ other: T) throws -> T {
        guard `is`(other[]) else {
            throw error(message: "\(self) is not a \(other)")
        }
        return T(id)
    }
}

extension Tag {

    public func `is`(_ type: L) -> Bool {
        `is`(type[])
    }

    public func `is`(_ types: L...) -> Bool {
        for type in types where isNot(type) { return false }
        return true
    }

    public func `is`(_ tag: Tag) -> Bool {
        type[tag.id] != nil
    }

    public func `is`(_ types: Tag...) -> Bool {
        for type in types where isNot(type) { return false }
        return true
    }

    public func `is`<S: Sequence>(_ types: S) -> Bool where S.Element == Tag {
        for type in types where isNot(type) { return false }
        return true
    }

    public func isNot(_ type: L) -> Bool {
        `is`(type) == false
    }

    public func isNot(_ type: Tag) -> Bool {
        `is`(type) == false
    }
}

public func ~= (lhs: L, rhs: L) -> Bool {
    rhs[].is(lhs[])
}

public func ~= (lhs: L, rhs: Tag) -> Bool {
    rhs.is(lhs[])
}

public func ~= (lhs: Tag, rhs: L) -> Bool {
    rhs[].is(lhs)
}

public func ~= (lhs: Tag, rhs: Tag) -> Bool {
    rhs.is(lhs)
}

extension Tag {

    public func isAncestor(of other: Tag) -> Bool {
        id.isDotPathAncestor(of: other.id)
    }

    public func isDescendant(of other: Tag) -> Bool {
        id.isDotPathDescendant(of: other.id)
    }

    public func idRemainder(after tag: Tag) throws -> Substring {
        guard isDescendant(of: tag) else {
            throw error(message: "\(tag) is not an ancestor of \(self)")
        }
        return id.dotPath(after: tag.id)
    }
}

public func ~= <T>(pattern: (T) -> Bool, value: T) -> Bool {
    pattern(value)
}

public func isAncestor(of a: L) -> (Tag) -> Bool {
    isAncestor(of: a[])
}

public func isAncestor(of a: Tag) -> (Tag) -> Bool {
    { b in b.isAncestor(of: a) }
}

public func isDescendant(of a: L) -> (Tag) -> Bool {
    isDescendant(of: a[])
}

public func isDescendant(of a: Tag) -> (Tag) -> Bool {
    { b in b.isDescendant(of: a) }
}

extension Tag {

    public subscript(descendant: Name...) -> Tag? {
        self[descendant]
    }

    public subscript<Descendant>(
        descendant: Descendant
    ) -> Tag? where Descendant: Collection, Descendant.Element == Name {
        var result = self
        for name in descendant {
            guard let tag = result.children[name] else {
                return nil
            }
            result = (try? tag.node.protonym.map { try Tag(id: $0, in: language) }) ?? tag
        }
        return result
    }

    public func child(named name: Name) throws -> Tag {
        guard let child = children[name] else {
            throw error(message: "\(self) does not have a child '\(name)' - it has children: \(children)")
        }
        return child
    }
}

extension Tag {

    static func isCollection(_ tag: Tag) -> Bool {
        tag.is(blockchain.db.collection)
    }

    static func isLeaf(_ tag: Tag) -> Bool {
        guard tag.parent != nil else { return false }
        return !tag.is(blockchain.session.state.value)
            && !tag.isLeafDescendant
            && (tag.children.isEmpty || tag.is(blockchain.db.leaf))
    }

    static func isLeafDescendant(_ tag: Tag) -> Bool {
        guard let parent = tag.parent else { return false }
        return parent.isLeafDescendant || parent.isLeaf
    }
}

extension Tag {

    @discardableResult
    static func add(parent: ID?, node: Lexicon.Graph.Node, to language: Language) -> Tag {
        let id = parent?.dot(node.name) ?? node.name
        if let node = language.nodes[id] { return node }
        let tag = Tag(parent: parent, node: node, in: language)
        language.nodes[tag.id] = tag
        return tag
    }

    static func lineage(of id: Tag) -> UnfoldFirstSequence<Tag> {
        sequence(first: id, next: \.parent)
    }

    static func protonym(of tag: Tag) -> Tag? {
        guard let suffix = tag.node.protonym else {
            return nil
        }
        guard let parent = tag.parent else {
            assertionFailure("Synonym '\(suffix)', tag '\(tag.id)', does not have a parent.")
            return nil
        }
        guard let protonym = parent[suffix.components(separatedBy: ".")] else {
            assertionFailure("Could not find protonym '\(suffix)' of \(tag.id)")
            return nil
        }

        tag.language.nodes[tag.id] = protonym // MARK: always map synonym to its protonym

        return .init(protonym)
    }

    static func children(of tag: Tag) -> [Name: Tag] {
        if let protonym = tag.protonym {
            var children: [Name: Tag] = [:]
            for (name, child) in protonym.children {
                children[name] = Tag.add(parent: tag.id, node: child.node, to: tag.language)
            }
            return children
        } else {
            var ownChildren = tag.ownChildren
            for (_, type) in tag.ownType {
                for (name, child) in type.children {
                    ownChildren[name] = Tag.add(parent: tag.id, node: child.node, to: tag.language)
                }
            }
            return ownChildren
        }
    }

    static func ownType(_ tag: Tag) -> [ID: Tag] {
        var type: [ID: Tag] = [:]
        for id in tag.node.type {
            type[id] = tag.language.tag(id)
        }
        return type
    }

    static func type(of tag: Tag) -> [ID: Tag] {
        if let protonym = tag.node.protonym, let tag = tag.language.tag(protonym) {
            return tag.type
        }
        var type = tag.ownType
        type[tag.id] = tag
        for (_, tag) in tag.ownType {
            type.merge(tag.type) { o, _ in o }
        }
        return type
    }
}

extension Tag: Equatable, Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id && lhs.language == rhs.language
    }
}

extension CodingUserInfoKey {
    public static let language = CodingUserInfoKey(rawValue: "com.blockchain.namespace.language")!
}

extension Tag: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let language = decoder.userInfo[.language] as? Language ?? Language.root.language
        let id = try container.decode(String.self)
        try self.init(id: id, in: language)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}

extension Tag: CustomStringConvertible {
    public var description: String { id }
}
