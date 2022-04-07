// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import RxSwift

public protocol BitcoinCashWalletBridgeAPI {
    var defaultWallet: Single<BitcoinCashWalletAccount> { get }
    var wallets: Single<[BitcoinCashWalletAccount]> { get }

    func receiveAddress(forXPub xpub: String) -> Single<String>
    func firstReceiveAddress(forXPub xpub: String) -> Single<String>
    func update(accountIndex: Int, label: String) -> Completable

    func note(for transactionHash: String) -> Single<String?>

    func updateNote(for transactionHash: String, note: String?) -> Completable
}
