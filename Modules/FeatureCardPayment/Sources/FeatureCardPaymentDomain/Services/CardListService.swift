// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import Foundation
import NabuNetworkError
import ToolKit

final class CardListService: CardListServiceAPI {

    // MARK: - Public properties

    var cards: AnyPublisher<[CardData], Never> {
        repository.cards
    }

    // MARK: - Private properties

    private let repository: CardListRepositoryAPI
    private let featureFlagsService: FeatureFlagsServiceAPI

    // MARK: - Setup

    init(
        repository: CardListRepositoryAPI = resolve(),
        featureFlagsService: FeatureFlagsServiceAPI = resolve()
    ) {
        self.repository = repository
        self.featureFlagsService = featureFlagsService
    }

    func card(by identifier: String) -> AnyPublisher<CardData?, Never> {
        cards
            .map { $0.first(where: { $0.identifier == identifier }) }
            .eraseToAnyPublisher()
    }

    func fetchCards() -> AnyPublisher<[CardData], Never> {
        repository.fetchCardList()
    }

    func doesCardExist(number: String, expiryMonth: String, expiryYear: String) -> AnyPublisher<Bool, Never> {
        cards
            .map { cardsData in
                cardsData.contains { card in
                    card.number.suffix(4) == number.suffix(4) &&
                        card.month == expiryMonth &&
                        card.year.suffix(2) == expiryYear.suffix(2) &&
                        card.state != .blocked
                }
            }
            .eraseToAnyPublisher()
    }
}
