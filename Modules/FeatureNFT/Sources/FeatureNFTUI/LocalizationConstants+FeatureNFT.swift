// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Localization

// swiftlint:disable all

// MARK: Groups

extension LocalizationConstants {
    enum NFT {
        enum Screen {
            enum List {}
            enum Empty {}
            enum Detail {}
        }
    }
}

// MARK: - AssetListView

extension LocalizationConstants.NFT.Screen.List {
    static let fetchingYourNFTs = NSLocalizedString(
        "Fetching Your NFTs",
        comment: ""
    )
    static let shopOnOpenSea = NSLocalizedString(
        "Shop on OpenSea",
        comment: ""
    )
}

extension LocalizationConstants.NFT.Screen.Empty {
    static let headline = NSLocalizedString(
        "To get started, transfer your NFTs",
        comment: ""
    )
    static let subheadline = NSLocalizedString(
        "Send from any wallet, or buy from a marketplace!",
        comment: ""
    )
    static let copyEthAddress = NSLocalizedString(
        "Copy Ethereum Address",
        comment: ""
    )
    static let copied = NSLocalizedString(
        "Copied!",
        comment: ""
    )
}

// MARK: - AssetDetailView

extension LocalizationConstants.NFT.Screen.Detail {

    static let viewOnOpenSea = NSLocalizedString(
        "View on OpenSea",
        comment: ""
    )

    static let properties = NSLocalizedString(
        "Properties",
        comment: ""
    )

    static let creator = NSLocalizedString("Creator", comment: "")

    static let about = NSLocalizedString("About", comment: "")

    static let descripton = NSLocalizedString("Description", comment: "")

    static let readMore = NSLocalizedString("Read More", comment: "")
}
