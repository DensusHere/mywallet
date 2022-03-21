// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureCardPaymentDomain
import Foundation
import NabuNetworkError
import ToolKit

class CardListRepository: CardListRepositoryAPI {

    private struct Key: Hashable {}

    private let cachedValue: CachedValueNew<
        Key,
        [CardData],
        NabuNetworkError
    >
    var cards: AnyPublisher<[CardData], Never> {
        cachedValue
            .stream(key: Key())
            .map {
                switch $0 {
                case .success(let value):
                    return value
                case .failure:
                    return []
                }
            }
            .eraseToAnyPublisher()
    }

    init(
        cardListClient: CardListClientAPI = resolve(),
        featureFlagsService: FeatureFlagsServiceAPI = resolve()
    ) {
        let cache: AnyCache<Key, [CardData]> = InMemoryCache(
            configuration: .onLoginLogout(),
            refreshControl: PerpetualCacheRefreshControl()
        ).eraseToAnyCache()

        cachedValue = CachedValueNew(
            cache: cache,
            fetch: { _ in
                featureFlagsService.isEnabled(.remote(.newCardAcquirers))
                    .setFailureType(to: NabuNetworkError.self)
                    .flatMap { isEnabled -> AnyPublisher<[CardData], NabuNetworkError> in
                        cardListClient
                            .getCardList(enableProviders: isEnabled)
                            .compactMap { payloads in payloads.compactMap(CardData.init(response:)) }
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
        )
    }

    func card(by identifier: String) -> AnyPublisher<CardData?, Never> {
        cards
            .map { cards -> CardData? in
                cards.first(where: { card in card.identifier == identifier })
            }
            .eraseToAnyPublisher()
    }

    func fetchCardList() -> AnyPublisher<[CardData], Never> {
        cachedValue.get(key: Key(), forceFetch: true).replaceError(with: []).eraseToAnyPublisher()
    }
}
