// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation
import MoneyKit
import NetworkError

public protocol HistoricalPriceServiceAPI {

    func fetch(
        series: Series,
        relativeTo: Date
    ) -> AnyPublisher<GraphData, NetworkError>
}

public class HistoricalPriceService: HistoricalPriceServiceAPI {

    private let base: CryptoCurrency
    private let displayFiatCurrency: AnyPublisher<FiatCurrency, Never>
    private let historicalPriceRepository: HistoricalPriceRepositoryAPI

    public init(
        base: CryptoCurrency,
        displayFiatCurrency: AnyPublisher<FiatCurrency, Never>,
        historicalPriceRepository: HistoricalPriceRepositoryAPI
    ) {
        self.base = base
        self.displayFiatCurrency = displayFiatCurrency
        self.historicalPriceRepository = historicalPriceRepository
    }

    public func fetch(series: Series, relativeTo: Date) -> AnyPublisher<GraphData, NetworkError> {
        displayFiatCurrency.flatMap { [base, historicalPriceRepository] fiatCurrency in
            historicalPriceRepository.fetchGraphData(
                base: base,
                quote: fiatCurrency,
                series: series,
                relativeTo: relativeTo
            )
        }
        .eraseToAnyPublisher()
    }
}
