// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Combine
import DIKit
import MoneyKit

public protocol CryptoAssetRepositoryAPI {

    var nonCustodialGroup: AnyPublisher<AccountGroup?, Never> { get }

    var canTransactToCustodial: AnyPublisher<Bool, Never> { get }

    func accountGroup(
        filter: AssetFilter
    ) -> AnyPublisher<AccountGroup?, Never>

    func parse(
        address: String,
        memo: String?
    ) -> AnyPublisher<ReceiveAddress?, Never>

    func parse(
        address: String,
        memo: String?,
        label: String,
        onTxCompleted: @escaping (TransactionResult) -> AnyPublisher<Void, Error>
    ) -> Result<CryptoReceiveAddress, CryptoReceiveAddressFactoryError>
}
