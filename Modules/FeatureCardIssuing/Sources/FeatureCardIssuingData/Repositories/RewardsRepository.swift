// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureCardIssuingDomain
import Foundation
import NabuNetworkError

final class RewardsRepository: RewardsRepositoryAPI {

    private let client: RewardsClientAPI

    init(
        client: RewardsClientAPI
    ) {
        self.client = client
    }

    func fetchRewards() -> AnyPublisher<[Reward], NabuNetworkError> {
        client.fetchRewards()
    }

    /// returns linked reward ids to the card
    func fetchRewards(for card: Card) -> AnyPublisher<[String], NabuNetworkError> {
        client.fetchRewards(for: card.cardId)
    }

    func update(rewards: [Reward], for card: Card) -> AnyPublisher<[String], NabuNetworkError> {
        client.update(rewards: rewards.map(\.id), for: card.cardId)
    }
}
