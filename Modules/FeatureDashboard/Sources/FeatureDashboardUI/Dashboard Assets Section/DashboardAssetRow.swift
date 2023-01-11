// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import ComposableArchitecture
import FeatureDashboardDomain
import Foundation
import SwiftUI

public enum PresentedAssetType: Decodable {
    case custodial
    case nonCustodial

    var assetDisplayLimit: Int {
        isCustodial ? 8 : 5
    }

    var isCustodial: Bool {
        self == .custodial
    }

    var rowType: PresentedAssetRowType {
        switch self {
        case .custodial:
            return .custodial
        case .nonCustodial:
            return .nonCustodial
        }
    }
}

public enum PresentedAssetRowType: Decodable {
    case custodial
    case nonCustodial
    case fiat

    var isCustodial: Bool {
        self == .custodial
    }
}

public struct DashboardAssetRow: ReducerProtocol {
    public let app: AppProtocol
    public init(
        app: AppProtocol
    ) {
        self.app = app
    }

    public enum Action: Equatable {
        case onAssetTapped
    }

    public struct State: Equatable, Identifiable {
        public var id: String {
            asset.id
        }

        var type: PresentedAssetRowType
        var asset: AssetBalanceInfo
        var isLastRow: Bool

        var trailingDescriptionString: String {
            switch type {
            case .custodial:
                return asset.priceChangeString ?? ""
            case .nonCustodial:
                return asset.cryptoBalance.toDisplayString(includeSymbol: true)
            case .fiat:
                return asset.cryptoBalance.toDisplayString(includeSymbol: true)
            }
        }

        var trailingDescriptionColor: Color? {
            type.isCustodial ? asset.priceChangeColor : nil
        }

        public init(
            type: PresentedAssetRowType,
            isLastRow: Bool,
            asset: AssetBalanceInfo
        ) {
            self.type = type
            self.asset = asset
            self.isLastRow = isLastRow
        }
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAssetTapped:
                print(state.asset)
                return .fireAndForget { [assetInfo = state.asset] in
                    print(assetInfo)
                    app.post(
                        action: blockchain.ux.asset.select.then.enter.into,
                        value: blockchain.ux.asset[assetInfo.currency.code],
                        context: [blockchain.ux.asset.select.origin: "ASSETS"]
                    )
                }
            }
        }
    }
}
