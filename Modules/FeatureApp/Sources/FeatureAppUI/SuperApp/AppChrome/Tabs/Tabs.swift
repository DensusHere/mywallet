// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import Collections
import ErrorsUI
import Foundation
import SwiftExtensions

// Copied over from `RootView`

/// A helper for decoding a collection of `Tab` that ignores unknown or misconfigured ones.
struct TabConfig: Decodable {

    let tabs: OrderedSet<Tab>

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let optionalTabs = try container.decode([FailableDecodable<Tab>].self)
        self.tabs = OrderedSet(uncheckedUniqueElements: optionalTabs.compactMap(\.value))
    }
}

struct Tab: Hashable, Identifiable, Codable {
    var id: AnyHashable { tag }
    var tag: Tag.Reference
    var name: String
    var ux: UX.Dialog?
    var url: URL?
    var icon: Icon
    var unselectedIcon: Icon?
}

extension Tab: CustomStringConvertible {
    var description: String { tag.string }
}

extension Tab {

    var ref: Tag.Reference { tag }

    // swiftlint:disable force_try

    // OA Add support for pathing directly into a reference
    // e.g. ref.descendant(blockchain.ux.type.story, \.entry)
    func entry() -> Tag.Reference {
        try! ref.tag.as(blockchain.ux.type.story).entry[].ref(to: ref.context)
    }
}
