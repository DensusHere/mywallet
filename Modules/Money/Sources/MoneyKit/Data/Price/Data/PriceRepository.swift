// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import Errors
import Foundation
import ToolKit

final class PriceRepository: PriceRepositoryAPI {

    // MARK: - Setup

    private let client: PriceClientAPI
    private let indexMultiCachedValue: CachedValueNew<
        PriceRequest.IndexMulti.Key,
        [String: PriceQuoteAtTime],
        NetworkError
    >
    private let symbolsCachedValue: CachedValueNew<
        PriceRequest.Symbols.Key,
        CurrencySymbols,
        NetworkError
    >

    private let indexSeriesCachedValue: CachedValueNew<
        PriceRequest.IndexSeries.Key,
        HistoricalPriceSeries,
        NetworkError
    >

    private let topMoversCachedValue: CachedValueNew<
        PriceRequest.TopMovers.Key,
        [TopMoverInfo],
        NetworkError
    >

    // MARK: - Setup

    init(
        client: PriceClientAPI,
        refreshControl: CacheRefreshControl = PeriodicCacheRefreshControl(refreshInterval: 180)
    ) {
        self.client = client
        let indexMultiCache = InMemoryCache<PriceRequest.IndexMulti.Key, [String: PriceQuoteAtTime]>(
            configuration: .default(),
            refreshControl: refreshControl
        )
            .eraseToAnyCache()

        let topMoversCache = InMemoryCache<PriceRequest.TopMovers.Key, [TopMoverInfo]>(
            configuration: .onLoginLogoutTransactionAndDashboardRefresh(),
            refreshControl: PeriodicCacheRefreshControl(refreshInterval: 60)
        )
        .eraseToAnyCache()

        self.indexMultiCachedValue = CachedValueNew(
            cache: indexMultiCache,
            fetch: { key in
                client
                    .price(of: key.base, in: key.quote.code, time: key.time.timestamp)
                    .map(\.entries)
                    .map { entries in
                        entries.compactMapValues { item in
                            item
                                .flatMap {
                                    PriceQuoteAtTime(
                                        response: $0,
                                        currency: key.quote.currencyType
                                    )
                                }
                        }
                    }
                    .eraseToAnyPublisher()
            }
        )
        let symbolsCache = InMemoryCache<PriceRequest.Symbols.Key, CurrencySymbols>(
            configuration: .default(),
            refreshControl: PerpetualCacheRefreshControl()
        )
        .eraseToAnyCache()

        self.symbolsCachedValue = CachedValueNew(
            cache: symbolsCache,
            fetch: { _ in
                client.symbols()
            }
        )

        self.indexSeriesCachedValue = CachedValueNew(
            cache: InMemoryCache(
                configuration: .default(),
                refreshControl: PerpetualCacheRefreshControl()
            ).eraseToAnyCache(),
            fetch: { key in
                let start: TimeInterval = key.window.timeIntervalSince1970(
                    calendar: .current,
                    date: Date()
                )
                return client
                    .priceSeries(
                        of: key.base.code,
                        in: key.quote.code,
                        start: start.string(with: 0),
                        scale: String(key.window.scale)
                    )
                    .map { response in
                        HistoricalPriceSeries(baseCurrency: key.base, quoteCurrency: key.quote, prices: response)
                    }
                    .eraseToAnyPublisher()
            }
        )

        self.topMoversCachedValue = CachedValueNew(
            cache: topMoversCache,
            fetch: { [client] key in
                client
                    .topMovers(
                        with: key.currency,
                        topFirst: 100,
                        custodialOnly: key.custodialOnly
                    )
                    .map { response in
                        response.topMoversDescending
                            .compactMap { item -> TopMoverInfo? in

                            guard let currency = CryptoCurrency(code: item.currency) else {
                                return nil
                            }

                            guard (currency.supports(product: .custodialWalletBalance) && key.custodialOnly) || !key.custodialOnly else {
                                    return nil
                              }

                            guard item.percentageDelta > -1 else {
                                return nil
                            }

                            return TopMoverInfo(
                                currency: currency,
                                delta: item.percentageDelta,
                                lastPrice: .create(major: item.lastPrice, currency: .fiat(key.currency))
                            )
                            }
                    .array
                    }
                    .eraseToAnyPublisher()
            }
        )
    }

    func symbols() -> AnyPublisher<CurrencySymbols, NetworkError> {
        symbolsCachedValue.get(key: PriceRequest.Symbols.Key())
    }

    func topMovers(
        currency: FiatCurrency,
        custodialOnly: Bool
    ) -> AnyPublisher<Result<[TopMoverInfo], NetworkError>, Never> {
        topMoversCachedValue.stream(
            key: .init(
                currency: currency,
                custodialOnly: custodialOnly
            ),
            skipStale: true
        )
    }

    func stream(
        bases: [Currency],
        quote: Currency,
        at time: PriceTime,
        skipStale: Bool
    ) -> AnyPublisher<Result<[String: PriceQuoteAtTime], NetworkError>, Never> {
        let bases = Set(bases.map(\.code))
        return symbolsCachedValue
            .stream(
                key: PriceRequest.Symbols.Key(),
                skipStale: skipStale
            )
            .map { symbols in
                symbols.map(\.base.keys).map(Set.init)
            }
            .flatMap { [indexMultiCachedValue] symbols -> AnyPublisher<Result<[String: PriceQuoteAtTime], NetworkError>, Never> in
                indexMultiCachedValue.stream(
                    key: PriceRequest.IndexMulti.Key(
                        base: Set(symbols).intersection(bases),
                        quote: quote.currencyType,
                        time: time
                    ),
                    skipStale: skipStale
                )
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func prices(
        of bases: [Currency],
        in quote: Currency,
        at time: PriceTime
    ) -> AnyPublisher<[String: PriceQuoteAtTime], NetworkError> {
        stream(bases: bases, quote: quote, at: time, skipStale: true)
            .first()
            .get()
            .eraseToAnyPublisher()
    }

    func priceSeries(
        of base: CryptoCurrency,
        in quote: FiatCurrency,
        within window: PriceWindow
    ) -> AnyPublisher<HistoricalPriceSeries, NetworkError> {
        indexSeriesCachedValue.get(key: .init(base: base, quote: quote, window: window))
    }
}

extension HistoricalPriceSeries {

    init(baseCurrency: CryptoCurrency, quoteCurrency: Currency, prices: [Price]) {
        self.init(
            currency: baseCurrency,
            prices: prices.compactMap { item in
                PriceQuoteAtTime(response: item, currency: quoteCurrency)
            }
        )
    }
}

extension PriceQuoteAtTime {

    init?(response: Price, currency: Currency) {
        guard let price = response.price else {
            return nil
        }
        self.init(
            timestamp: response.timestamp,
            moneyValue: .create(
                major: price,
                currency: currency.currencyType
            ),
            marketCap: response.marketCap,
            volume24h: response.volume24h
        )
    }
}
