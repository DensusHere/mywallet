// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import NetworkKit
import ToolKit

// MARK: - PriceRequest

enum PriceRequest {
    enum IndexMulti {}
    enum IndexMultiSeries {}
    enum IndexSeries {}
    enum Symbols {}
    enum TopMovers {}
}

// MARK: - IndexSeries

extension PriceRequest.IndexSeries {

    struct Key: Hashable {

        let base: CryptoCurrency
        let quote: FiatCurrency
        let window: PriceWindow

        init(base: CryptoCurrency, quote: FiatCurrency, window: PriceWindow) {
            self.base = base
            self.quote = quote
            self.window = window
        }
    }

    static func request(
        requestBuilder: RequestBuilder,
        base: String,
        quote: String,
        start: String,
        scale: String
    ) -> NetworkRequest? {
        requestBuilder.get(
            path: "/price/index-series",
            parameters: [
                URLQueryItem(name: "base", value: base),
                URLQueryItem(name: "quote", value: quote),
                URLQueryItem(name: "start", value: start),
                URLQueryItem(name: "scale", value: scale)
            ]
        )
    }
}

// MARK: - IndexMulti

extension PriceRequest.IndexMulti {

    struct Key: Hashable {
        let base: Set<String>
        let quote: CurrencyType
        let time: PriceTime

        init(base: Set<String>, quote: CurrencyType, time: PriceTime) {
            self.base = base
            self.quote = quote
            self.time = time
        }
    }

    private struct Pair: Encodable {
        let base: String
        let quote: String
    }

    /// Aggregated call for multiple price quotes.
    /// - parameter base: Base fiat currency code. Must be supported in https://api.blockchain.info/price/symbols
    /// - parameter quote: Currencies to quote, fiat or crypto.
    /// - parameter time: The epoch seconds used to locate a time in the past.
    static func request(
        requestBuilder: RequestBuilder,
        bases: Set<String>,
        quote: String,
        time: String?
    ) -> NetworkRequest? {
        requestBuilder.post(
            path: "/price/index-multi",
            parameters: time.flatMap { [URLQueryItem(name: "time", value: $0)] },
            body: try? bases.map { Pair(base: $0, quote: quote) }.encode()
        )
    }

    static func request(
        requestBuilder: RequestBuilder,
        pairs: [CurrencyPair]
    ) -> NetworkRequest? {
        requestBuilder.post(
            path: "/price/index-multi",
            body: try? pairs.map { Pair(base: $0.base.code, quote: $0.quote.code) }.encode()
        )
    }
}

extension PriceRequest.IndexMultiSeries {

    typealias Key = [CurrencyPairAndTime]

    /// Aggregated call for multiple price quotes.
    /// - parameter base: Base fiat currency code. Must be supported in https://api.blockchain.info/price/symbols
    /// - parameter quote: Currencies to quote, fiat or crypto.
    /// - parameter time: The epoch seconds used to locate a time in the past.
    static func request(
        requestBuilder: RequestBuilder,
        pairs: Key
    ) -> NetworkRequest? {
        requestBuilder.post(
            path: "/price/index-multi-series",
            body: try? pairs.encode()
        )
    }
}

// MARK: - Symbols

extension PriceRequest.Symbols {

    struct Key: Hashable {}

    /// Aggregated call for multiple price quotes.
    /// - parameter base: Base fiat currency code. Must be supported in https://api.blockchain.info/price/symbols
    /// - parameter quote: Currencies to quote, fiat or crypto.
    /// - parameter time: The epoch seconds used to locate a time in the past.
    static func request(
        requestBuilder: RequestBuilder
    ) -> NetworkRequest? {
        requestBuilder.get(
            path: "/price/symbols"
        )
    }
}


// MARK: - Top Movers
extension PriceRequest.TopMovers {

    struct Key: Hashable, CustomStringConvertible {
        let currency: FiatCurrency
        var description: String { "id-\(currency)" }
    }

    /// Aggregated call for multiple price quotes.
    /// - parameter base: Base fiat currency code. Must be supported in https://api.blockchain.info/price/top-movers-24h
    /// - parameter quote: Currencies to quote, fiat or crypto.
    /// - parameter time: The epoch seconds used to locate a time in the past.
    static func request(
        requestBuilder: RequestBuilder,
        fiatBase: String,
        topN: String,
        custodialOnly: String
    ) -> NetworkRequest? {
        requestBuilder.get(
            path: "/price/top-movers-24h",
            parameters: [
                URLQueryItem(name: "fiatBase", value: fiatBase),
                URLQueryItem(name: "topN", value: topN),
                URLQueryItem(name: "custodialOnly", value: custodialOnly)
            ]
        )
    }
}
