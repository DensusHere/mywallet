// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import FeatureReferralDomain
import SwiftUI

public struct ReferFriendState: Equatable {
    var codeIsCopied: Bool
    var referralInfo: Referral
    @BindableState var isShareModalPresented: Bool = false
    @BindableState var isShowReferralViewPresented: Bool = false

    public init(
        codeIsCopied: Bool = false,
        referralInfo: Referral
    ) {
        self.codeIsCopied = codeIsCopied
        self.referralInfo = referralInfo
    }
}
