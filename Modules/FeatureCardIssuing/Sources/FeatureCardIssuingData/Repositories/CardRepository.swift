// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors
import FeatureCardIssuingDomain
import Foundation
import NetworkKit
import PassKit
import ToolKit

final class CardRepository: CardRepositoryAPI {

    private static let marqetaPath = "/marqeta-card/#/"

    private struct AccountKey: Hashable {
        let id: String
    }

    private let client: CardClientAPI
    private let userInfoProvider: UserInfoProviderAPI

    private let baseCardHelperUrl: String

    private let cachedCardValue: CachedValueNew<
        String,
        [Card],
        NabuNetworkError
    >

    private let cachedAccountValue: CachedValueNew<
        AccountKey,
        AccountCurrency,
        NabuNetworkError
    >

    private let accountCache: AnyCache<AccountKey, AccountCurrency>
    private let cardCache: AnyCache<String, [Card]>

    init(
        client: CardClientAPI,
        userInfoProvider: UserInfoProviderAPI,
        baseCardHelperUrl: String
    ) {
        self.client = client
        self.userInfoProvider = userInfoProvider
        self.baseCardHelperUrl = baseCardHelperUrl

        let cardCache: AnyCache<String, [Card]> = InMemoryCache(
            configuration: .onLoginLogout(),
            refreshControl: PerpetualCacheRefreshControl()
        ).eraseToAnyCache()

        cachedCardValue = CachedValueNew(
            cache: cardCache,
            fetch: { _ in
                client.fetchCards()
            }
        )

        self.cardCache = cardCache

        let accountCache: AnyCache<AccountKey, AccountCurrency> = InMemoryCache(
            configuration: .onLoginLogout(),
            refreshControl: PerpetualCacheRefreshControl()
        ).eraseToAnyCache()

        cachedAccountValue = CachedValueNew(
            cache: accountCache,
            fetch: { accountKey in
                client.fetchLinkedAccount(with: accountKey.id)
            }
        )

        self.accountCache = accountCache
    }

    func orderCard(
        product: Product,
        at address: Card.Address?
    ) -> AnyPublisher<Card, NabuNetworkError> {
        client
            .orderCard(
                with: .init(productCode: product.productCode, shippingAddress: address)
            )
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.cachedCardValue.invalidateCache()
            })
            .eraseToAnyPublisher()
    }

    func fetchCards() -> AnyPublisher<[Card], NabuNetworkError> {
        cachedCardValue.get(key: #file)
    }

    func fetchCard(with id: String) -> AnyPublisher<Card, NabuNetworkError> {
        client.fetchCard(with: id)
    }

    func delete(card: Card) -> AnyPublisher<Card, NabuNetworkError> {
        client
            .deleteCard(with: card.id)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.cachedCardValue.invalidateCache()
            }, receiveCompletion: { [weak self] _ in
                self?.cachedCardValue.invalidateCache()
            })
            .eraseToAnyPublisher()
    }

    func helperUrl(for card: Card) -> AnyPublisher<URL, NabuNetworkError> {
        let baseCardHelperUrl = baseCardHelperUrl
        return client
            .generateSensitiveDetailsToken(with: card.id)
            .replaceError(with: "-")
            .setFailureType(to: NabuNetworkError.self)
            .combineLatest(userInfoProvider.fullName)
            .map { token, fullName in
                Self.buildCardHelperUrl(
                    with: baseCardHelperUrl,
                    token: token,
                    for: card,
                    with: fullName
                )
            }
            .eraseToAnyPublisher()
    }

    func fetchLinkedAccount(for card: Card) -> AnyPublisher<AccountCurrency, NabuNetworkError> {
        cachedAccountValue.get(key: AccountKey(id: card.id))
    }

    func update(account: AccountBalance, for card: Card) -> AnyPublisher<AccountCurrency, NabuNetworkError> {
        client
            .updateAccount(
                with: AccountCurrency(accountCurrency: account.balance.symbol),
                for: card.id
            )
            .flatMap { [accountCache] accountCurrency in
                accountCache
                    .set(accountCurrency, for: AccountKey(id: card.id))
                    .replaceOutput(with: accountCurrency)
            }
            .eraseToAnyPublisher()
    }

    func eligibleAccounts(for card: Card) -> AnyPublisher<[AccountBalance], NabuNetworkError> {
        client.eligibleAccounts(for: card.id)
    }

    func lock(card: Card) -> AnyPublisher<Card, NabuNetworkError> {
        client
            .lock(cardId: card.id)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.cachedCardValue.invalidateCache()
            })
            .eraseToAnyPublisher()
    }

    func unlock(card: Card) -> AnyPublisher<Card, NabuNetworkError> {
        client
            .unlock(cardId: card.id)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.cachedCardValue.invalidateCache()
            })
            .eraseToAnyPublisher()
    }

    func tokenise(
        card: Card,
        with certificates: [Data],
        nonce: Data,
        nonceSignature: Data
    ) -> AnyPublisher<PKAddPaymentPassRequest, NabuNetworkError> {
        client.tokenise(
            cardId: card.id,
            with: TokeniseCardParameters(
                certificates: certificates,
                nonce: nonce,
                nonceSignature: nonceSignature
            )
        )
        .map(PKAddPaymentPassRequest.init)
        .eraseToAnyPublisher()
    }

    func fulfillment(card: Card) -> AnyPublisher<Card.Fulfillment, NabuNetworkError> {
        client.fulfillment(cardId: card.id)
    }

    func pinWidgetUrl(card: Card) -> AnyPublisher<URL, NabuNetworkError> {
        client.pinWidgetUrl(cardId: card.id)
    }

    func activateWidgetUrl(card: Card) -> AnyPublisher<URL, NabuNetworkError> {
        client.activateWidgetUrl(cardId: card.id)
    }

    func fetchStatements() -> AnyPublisher<[Statement], NabuNetworkError> {
        client.fetchStatements()
    }

    func fetchStatementUrl(statement: Statement) -> AnyPublisher<URL, NabuNetworkError> {
        client.fetchStatementUrl(statementId: statement.statementId)
    }

    private static func buildCardHelperUrl(
        with base: String,
        token: String,
        for card: Card,
        with name: String
    ) -> URL {
        let nameParam = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "-"
        return URL(
            string: "\(base)\(Self.marqetaPath)\(token)/\(card.last4)/\(nameParam)"
        )!
    }
}

extension PKAddPaymentPassRequest {

    convenience init(
        _ response: TokeniseCardResponse
    ) {
        self.init()
        activationData = Data(base64Encoded: response.activationData)
        ephemeralPublicKey = Data(base64Encoded: response.ephemeralPublicKey)
        encryptedPassData = Data(base64Encoded: response.encryptedPassData)
    }
}
