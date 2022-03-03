// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import FeatureCoinDomain

public enum CoinViewAction {
    case loadKycStatus
    case updateKycStatus(KYCStatus)
    case loadAccounts
    case updateAccounts([Account])
    case updateHasPositiveBalanceForSelling(Bool)
    case graph(GraphViewAction)
}
