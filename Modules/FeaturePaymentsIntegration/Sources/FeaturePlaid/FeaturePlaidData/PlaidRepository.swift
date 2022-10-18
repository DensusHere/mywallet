// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors
import FeaturePlaidDomain

public struct PlaidRepository: PlaidRepositoryAPI {
    private let client: PlaidClientAPI

    public init(client: PlaidClientAPI) {
        self.client = client
    }

    // MARK: - Get link token

    /// Get token to link a new bank
    public func getLinkToken(
    ) -> AnyPublisher<LinkAccountInfo, NabuError> {
        client
            .getLinkToken(body: .init())
            .map { response in
                LinkAccountInfo(
                    id: response.id,
                    linkToken: response.attributes.linkToken
                )
            }
            .eraseToAnyPublisher()
    }

    /// Get link token to migrate or renew linking of a specific account id
    public func getLinkToken(
        accountId: String
    ) -> AnyPublisher<LinkAccountInfo, NabuError> {
        client
            .getLinkToken(accountId: accountId, body: .init())
            .map { response in
                LinkAccountInfo(
                    id: response.id,
                    linkToken: response.attributes.linkToken
                )
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Update account form BE with new Plaid data

    /// Send the success Plaid data to the BE after linking a new bank or updating an anready linked account
    public func updatePlaidAccount(
        _ accountId: String,
        attributes: PlaidAccountAttributes
    ) -> AnyPublisher<Bool, NabuError> {
        let request = UpdatePlaidAccountRequest(
            accountId: attributes.accountId,
            publicToken: attributes.publicToken
        )
        return client
            .updatePlaidAccount(accountId, body: request)
            .map { response in
                debugPrint(response)
                return true
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Get a list of linked banks

    public func getLinkedBanks(
    ) -> AnyPublisher<[LinkedBankData], NabuError> {
        client
            .getLinkedBanks()
            .map { response -> [LinkedBankData] in
                response
                    .compactMap { response in
                        LinkedBankData(
                            identifier: response.id,
                            state: response.state,
                            partner: .init(response.partner)
                        )
                    }
                    .filter(\.isActive)
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Pool until account is active

    public func waitForActivationOfLinkedBank(
        id accountId: String
    ) -> AnyPublisher<LinkedBankData?, NabuError> {
        getLinkedBanks()
            .startPolling(
                timeoutInterval: .seconds(15),
                retryInterval: .seconds(1),
                until: { response in
                    response
                        .first(where: { account in
                            account.identifier == accountId
                                && account.isLinkedWithPlaid
                        })
                        .isNotNil
                }
            )
            .map { accounts in
                accounts.first(where: { $0.identifier == accountId })
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Get settlement info to see if account needs to be renewed/migrated

    public func getSettlementInfo(
        accountId: String,
        amount: String
    ) -> AnyPublisher<SettlementInfo, NabuError> {
        client
            .getSettlementInfo(
                accountId: accountId,
                amount: amount
            )
            .map { response in
                let settlement = response.attributes.settlementResponse
                return SettlementInfo(
                    id: response.id,
                    partner: response.partner,
                    state: response.state,
                    settlement: .init(
                        settlementType: settlement.settlementType,
                        reason: settlement.reason
                    )
                )
            }
            .eraseToAnyPublisher()
    }
}
