// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation

public struct Account: Equatable {
    public let index: Int
    public let label: String
    public let archived: Bool
    public let defaultDerivation: DerivationType
    public let derivations: [Derivation]

    var defaultDerivationAccount: Derivation? {
        derivations.first(where: { $0.type == defaultDerivation })
    }

    public init(
        index: Int,
        label: String,
        archived: Bool,
        defaultDerivation: DerivationType,
        derivations: [Derivation]
    ) {
        self.index = index
        self.label = label
        self.archived = archived
        self.defaultDerivation = defaultDerivation
        self.derivations = derivations
    }

    func derivation(for format: DerivationType) -> Derivation? {
        derivations.first { $0.type == format }
    }
}

func createAccount(
    label: String,
    derivations: [Derivation]
) -> Account {
    Account(
        index: 0,
        label: label,
        archived: false,
        defaultDerivation: .segwit,
        derivations: derivations
    )
}
