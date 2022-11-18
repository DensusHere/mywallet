// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors
import Foundation
import PassKit

public protocol CardRepositoryAPI {

    func orderCard(product: Product, at address: Card.Address?) -> AnyPublisher<Card, NabuNetworkError>

    func fetchCards() -> AnyPublisher<[Card], NabuNetworkError>

    func fetchCard(with id: String) -> AnyPublisher<Card?, NabuNetworkError>

    func delete(card: Card) -> AnyPublisher<Card, NabuNetworkError>

    /// generate the URL for the webview to display the card details
    func helperUrl(for card: Card) -> AnyPublisher<URL, NabuNetworkError>

    func fetchLinkedAccount(for card: Card) -> AnyPublisher<AccountCurrency, NabuNetworkError>

    func update(account: AccountBalance, for card: Card) -> AnyPublisher<AccountCurrency, NabuNetworkError>

    func eligibleAccounts(for card: Card) -> AnyPublisher<[AccountBalance], NabuNetworkError>

    func lock(card: Card) -> AnyPublisher<Card, NabuNetworkError>

    func unlock(card: Card) -> AnyPublisher<Card, NabuNetworkError>

    /// get request parameters to add card to Apple Wallet
    func tokenise(
        card: Card,
        with certificates: [Data],
        nonce: Data,
        nonceSignature: Data
    ) -> AnyPublisher<PKAddPaymentPassRequest, NabuNetworkError>

    func fulfillment(card: Card) -> AnyPublisher<Card.Fulfillment, NabuNetworkError>

    func pinWidgetUrl(card: Card) -> AnyPublisher<URL, NabuNetworkError>

    func activateWidgetUrl(card: Card) -> AnyPublisher<URL, NabuNetworkError>

    func fetchStatements() -> AnyPublisher<[Statement], NabuNetworkError>

    func fetchStatementUrl(statement: Statement) -> AnyPublisher<URL, NabuNetworkError>
}

public protocol UserInfoProviderAPI {
    var fullName: AnyPublisher<String, NabuNetworkError> { get }
}
