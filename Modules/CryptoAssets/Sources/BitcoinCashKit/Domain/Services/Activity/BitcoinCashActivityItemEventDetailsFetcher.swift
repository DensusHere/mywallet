// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BitcoinChainKit
import DIKit
import MoneyKit
import PlatformKit
import RxSwift

// swiftlint:disable type_name
final class BitcoinCashActivityItemEventDetailsFetcher: ActivityItemEventDetailsFetcherAPI {
    typealias Model = BitcoinCashActivityItemEventDetails

    private let repository: BitcoinCashWalletAccountRepository
    private let transactionsService: BitcoinCashHistoricalTransactionServiceAPI

    init(
        transactionsService: BitcoinCashHistoricalTransactionServiceAPI = resolve(),
        repository: BitcoinCashWalletAccountRepository = resolve()
    ) {
        self.transactionsService = transactionsService
        self.repository = repository
    }

    func details(
        for identifier: String,
        cryptoCurrency: CryptoCurrency
    ) -> Observable<BitcoinCashActivityItemEventDetails> {
        repository.accounts
            .map { accounts -> [XPub] in
                accounts.map(\.publicKey)
            }
            .eraseError()
            .flatMap { [transactionsService] publicKeys in
                transactionsService
                    .transaction(publicKeys: publicKeys, identifier: identifier)
                    .map(BitcoinCashActivityItemEventDetails.init(transaction:))
            }
            .asObservable()
    }
}
