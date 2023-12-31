// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import BlockchainNamespace
import Combine
@testable import FeatureDexDomain
@testable import FeatureDexUI
import Foundation
import MoneyKit
import XCTest

final class QuotePayloadFactoryTests: XCTestCase {

    func testOutputMajor() {
        _ = App.preview
        let quote = DexQuoteOutput(
            buyAmount: DexQuoteOutput.BuyAmount(amount: ether(major: 2), minimum: ether(major: 1)),
            field: .source,
            isValidated: true,
            networkFee: bitcoin(major: 0.01),
            productFee: ether(major: 0.1),
            sellAmount: bitcoin(major: 1),
            slippage: "0.1234",
            response: mockResponse
        )
        let result = QuotePayloadFactory.create(quote, service: EnabledCurrenciesService.default)!
        XCTAssertEqual(result.inputCurrency, "BTC")
        XCTAssertEqual(result.inputAmount, "1")

        XCTAssertEqual(result.outputCurrency, "ETH")
        XCTAssertEqual(result.expectedOutputAmount, "2")
        XCTAssertEqual(result.minOutputAmount, "1")

        XCTAssertEqual(result.slippageAllowed, "0.1234")
        XCTAssertEqual(result.networkFeeAmount, "0.01")
        XCTAssertEqual(result.networkFeeCurrency, "BTC")

        XCTAssertEqual(result.blockchainFeeAmount, "0.1")
        XCTAssertEqual(result.blockchainFeeCurrency, "ETH")
    }

    func testOutputLong() {
        _ = App.preview
        let quote = DexQuoteOutput(
            buyAmount: DexQuoteOutput.BuyAmount(
                amount: ether("2123456789123456789"),
                minimum: ether("1123456789123456789")
            ),
            field: .source,
            isValidated: true,
            networkFee: bitcoin("1234567"),
            productFee: ether("123456789123456789"),
            sellAmount: bitcoin("112345678"),
            slippage: "0.123456789",
            response: mockResponse
        )
        let result = QuotePayloadFactory.create(quote, service: EnabledCurrenciesService.default)!
        XCTAssertEqual(result.inputCurrency, "BTC")
        XCTAssertEqual(result.inputAmount, "1.12345678")

        XCTAssertEqual(result.outputCurrency, "ETH")
        XCTAssertEqual(result.expectedOutputAmount, "2.123456789123456789")
        XCTAssertEqual(result.minOutputAmount, "1.123456789123456789")

        XCTAssertEqual(result.slippageAllowed, "0.123456789")
        XCTAssertEqual(result.networkFeeAmount, "0.01234567")
        XCTAssertEqual(result.networkFeeCurrency, "BTC")

        XCTAssertEqual(result.blockchainFeeAmount, "0.123456789123456789")
        XCTAssertEqual(result.blockchainFeeCurrency, "ETH")
    }

    private func ether(major: Decimal) -> CryptoValue {
        CryptoValue.create(major: major, currency: .ethereum)
    }

    private func bitcoin(major: Decimal) -> CryptoValue {
        CryptoValue.create(major: major, currency: .bitcoin)
    }

    private func ether(_ minor: String) -> CryptoValue {
        CryptoValue.create(minor: minor, currency: .ethereum)!
    }

    private func bitcoin(_ minor: String) -> CryptoValue {
        CryptoValue.create(minor: minor, currency: .bitcoin)!
    }

    private var mockResponse: DexQuoteResponse {
        DexQuoteResponse(
            quote: .init(
                buyAmount: .init(amount: "0", symbol: "USDT"),
                sellAmount: .init(amount: "0", symbol: "USDT"),
                bcdcFee: .init(amount: "111000", symbol: "USDT"),
                gasFee: "777000000"
            ),
            tx: .init(data: "", gasLimit: "0", gasPrice: "0", value: "0", to: ""),
            legs: 1,
            quoteTtl: 15000
        )
    }
}
