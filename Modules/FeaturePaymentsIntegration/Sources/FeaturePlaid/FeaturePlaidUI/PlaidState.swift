// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import Errors

public struct PlaidState: Equatable {
    internal var accountId: String?
    internal let migratingAccount: Bool
    internal var uxError: UX.Error?

    public init(
        accountId: String? = nil,
        migratingAccount: Bool = false,
        uxError: UX.Error? = nil
    ) {
        self.accountId = accountId
        self.migratingAccount = migratingAccount
        self.uxError = uxError
    }
}
