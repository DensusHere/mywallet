// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import ToolKit

protocol SupportedAssetsRepositoryAPI {
    var ethereumERC20Assets: SupportedAssets { get }
    var polygonERC20Assets: SupportedAssets { get }
    var custodialAssets: SupportedAssets { get }
}

final class SupportedAssetsRepository: SupportedAssetsRepositoryAPI {

    let localService: SupportedAssetsServiceAPI

    private(set) lazy var ethereumERC20Assets: SupportedAssets = {
        switch localService.ethereumERC20Assets {
        case .success(let response):
            return SupportedAssets(response: response)
        case .failure(let error):
            if BuildFlag.isInternal {
                fatalError("Can' load local ERC20 assets. \(error.localizedDescription)")
            }
            return SupportedAssets.empty
        }
    }()

    private(set) lazy var polygonERC20Assets: SupportedAssets = {
        switch localService.polygonERC20Assets {
        case .success(let response):
            return SupportedAssets(response: response)
        case .failure(let error):
            if BuildFlag.isInternal {
                fatalError("Can' load local Polygon ERC20 assets. \(error.localizedDescription)")
            }
            return SupportedAssets.empty
        }
    }()

    private(set) lazy var custodialAssets: SupportedAssets = {
        switch localService.custodialAssets {
        case .success(let response):
            return SupportedAssets(response: response)
        case .failure(let error):
            if BuildFlag.isInternal {
                fatalError("Can' load local custodial assets. \(error.localizedDescription)")
            }
            return SupportedAssets.empty
        }
    }()

    init(localService: SupportedAssetsServiceAPI = resolve()) {
        self.localService = localService
    }
}
