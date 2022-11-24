// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DelegatedSelfCustodyDomain
import MoneyKit
import ToolKit

final class AddressesRepository: DelegatedCustodyAddressesRepositoryAPI {

    private let client: AccountDataClientAPI
    private let authenticationDataRepository: DelegatedCustodyAuthenticationDataRepositoryAPI
    private let cachedValue: CachedValueNew<
        String,
        [DelegatedCustodyAddress],
        Error
    >

    init(
        client: AccountDataClientAPI,
        authenticationDataRepository: DelegatedCustodyAuthenticationDataRepositoryAPI
    ) {
        self.client = client
        self.authenticationDataRepository = authenticationDataRepository
        let cache: AnyCache<String, [DelegatedCustodyAddress]> = InMemoryCache(
            configuration: .onLoginLogoutTransaction(),
            refreshControl: PeriodicCacheRefreshControl(refreshInterval: 120)
        ).eraseToAnyCache()
        self.cachedValue = CachedValueNew(
            cache: cache,
            fetch: { [authenticationDataRepository, client] key in
                authenticationDataRepository.authenticationData
                    .eraseError()
                    .flatMap { [client] authenticationData in
                        client.addresses(
                            guidHash: authenticationData.guidHash,
                            sharedKeyHash: authenticationData.sharedKeyHash,
                            currencies: [key]
                        )
                        .eraseError()
                    }
                    .map(DelegatedCustodyAddress.create(from:))
                    .eraseToAnyPublisher()
            }
        )
    }

    func addresses(for cryptoCurrency: CryptoCurrency) -> AnyPublisher<[DelegatedCustodyAddress], Error> {
        cachedValue.get(key: cryptoCurrency.code)
    }
}
