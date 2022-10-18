// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
@testable import MoneyDataKit

final class SupportedAssetsLocalFilePathProviderMock: SupportedAssetsFilePathProviderAPI {
    var remoteEthereumERC20Assets: URL?
    var localEthereumERC20Assets: URL?
    var remoteOtherERC20Assets: URL?
    var localOtherERC20Assets: URL?
    var remoteCustodialAssets: URL?
    var localCustodialAssets: URL?
}
