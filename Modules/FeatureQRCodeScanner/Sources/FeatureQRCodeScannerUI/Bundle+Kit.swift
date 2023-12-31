// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import ToolKit

private class BundleFinder {}
extension Bundle {
    public static let featureQRCodeScannerUI = Bundle.find(
        "FeatureQRCodeScanner_FeatureQRCodeScannerUI.bundle",
        in: BundleFinder.self
    )
}
