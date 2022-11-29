// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors
import FeatureCardIssuingDomain
import Foundation
import UIKit

protocol CardClientAPI {

    func orderCard(with parameters: OrderCardParameters) -> AnyPublisher<Card, NabuNetworkError>

    func fetchCards() -> AnyPublisher<[Card], NabuNetworkError>

    func fetchCard(with id: String) -> AnyPublisher<Card, NabuNetworkError>

    func deleteCard(with id: String) -> AnyPublisher<Card, NabuNetworkError>

    /// external token to be used in card plugin to retrieve PCI DSS scope card details, PAN, CVV
    func generateSensitiveDetailsToken(with cardId: String) -> AnyPublisher<String, NabuNetworkError>

    func fetchLinkedAccount(with cardId: String) -> AnyPublisher<AccountCurrency, NabuNetworkError>

    func updateAccount(
        with params: AccountCurrency,
        for cardId: String
    ) -> AnyPublisher<AccountCurrency, NabuNetworkError>

    func eligibleAccounts(for cardId: String) -> AnyPublisher<[AccountBalance], NabuNetworkError>

    func lock(cardId: String) -> AnyPublisher<Card, NabuNetworkError>

    func unlock(cardId: String) -> AnyPublisher<Card, NabuNetworkError>

    func tokenise(cardId: String, with parameters: TokeniseCardParameters) -> AnyPublisher<TokeniseCardResponse, NabuNetworkError>

    func fulfillment(cardId: String) -> AnyPublisher<Card.Fulfillment, NabuNetworkError>

    func pinWidgetUrl(cardId: String) -> AnyPublisher<URL, NabuNetworkError>

    func activateWidgetUrl(cardId: String) -> AnyPublisher<URL, NabuNetworkError>

    func fetchStatements() -> AnyPublisher<[Statement], NabuNetworkError>

    func fetchStatementUrl(statementId: String) -> AnyPublisher<URL, NabuNetworkError>
}

struct OrderCardParameters: Encodable {
    let productCode: String
    let shippingAddress: Card.Address?
}

struct TokeniseCardParameters: Encodable {

    enum DeviceType: String, Encodable {
        case phone = "MOBILE_PHONE"
        case tablet = "TABLET"
        case watch = "WATCH"
    }

    let deviceType: DeviceType
    let provisioningAppVersion: String?
    let certificates: [String]
    let nonce: String?
    let nonceSignature: String?

    init(
        certificates: [Data],
        nonce: Data,
        nonceSignature: Data
    ) {
        self.deviceType = UIDevice.current.userInterfaceIdiom == .phone ? .phone : .tablet
        self.provisioningAppVersion = Bundle.main.plist.version.string
        self.certificates = certificates.compactMap { data in
            data.base64EncodedString()
        }
        self.nonce = nonce.base64EncodedString()
        self.nonceSignature = nonceSignature.base64EncodedString()
    }
}

struct TokeniseCardResponse: Decodable {

    let cardId: String
    let encryptedPassData: String
    let activationData: String
    let ephemeralPublicKey: String
}

struct FetchUrlResponse: Decodable {
    let url: URL
}
