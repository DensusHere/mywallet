// Copyright © Blockchain Luxembourg S.A. All rights reserved.

/// A type of an `AssetModel`.
public enum AssetModelType: Hashable {

    public enum ERC20ParentChain: String {
        case ethereum = "ETH"
    }

    public enum CeloParentChain: String {
        case celo = "CELO"
    }

    /// A Celo token asset.
    case celoToken(parentChain: CeloParentChain)

    /// A coin asset.
    case coin(minimumOnChainConfirmations: Int)

    /// An Ethereum ERC-20 asset.
    case erc20(contractAddress: String, parentChain: ERC20ParentChain)

    /// A fiat asset.
    case fiat

    public var isERC20: Bool {
        switch self {
        case .erc20:
            return true
        case .coin, .fiat, .celoToken:
            return false
        }
    }

    public var isCoin: Bool {
        switch self {
        case .coin:
            return true
        case .erc20, .fiat, .celoToken:
            return false
        }
    }

    public var isCeloToken: Bool {
        switch self {
        case .celoToken:
            return true
        case .coin, .erc20, .fiat:
            return false
        }
    }
}