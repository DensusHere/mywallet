//
//  CryptoFormatterTests.swift
//  PlatformKitTests
//
//  Created by Chris Arriola on 12/5/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

@testable import PlatformKit
import XCTest

class CryptoFormatterTests: XCTestCase {
    private var englishLocale: Locale!
    private var btcFormatter: CryptoFormatter!
    private var ethFormatter: CryptoFormatter!
    private var bchFormatter: CryptoFormatter!
    private var xlmFormatter: CryptoFormatter!

    override func setUp() {
        super.setUp()
        self.englishLocale = Locale(identifier: "en_US")
        self.btcFormatter = CryptoFormatter(locale: englishLocale, cryptoCurrency: .bitcoin)
        self.ethFormatter = CryptoFormatter(locale: englishLocale, cryptoCurrency: .ethereum)
        self.bchFormatter = CryptoFormatter(locale: englishLocale, cryptoCurrency: .bitcoinCash)
        self.xlmFormatter = CryptoFormatter(locale: englishLocale, cryptoCurrency: .stellar)
    }

    func testFormatWithoutSymbolBtc() {
        XCTAssertEqual(
            "0.00000001",
            btcFormatter.format(value: CryptoValue.bitcoin(satoshis: 1))
        )
        XCTAssertEqual(
            "0.1",
            btcFormatter.format(value: CryptoValue.create(major: "0.1", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "0.0",
            btcFormatter.format(value: CryptoValue.create(major: "0", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1.0",
            btcFormatter.format(value: CryptoValue.create(major: "1", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1,000.0",
            btcFormatter.format(value: CryptoValue.create(major: "1000", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1,000,000.0",
            btcFormatter.format(value: CryptoValue.create(major: "1000000", currency: .bitcoin)!)
        )
    }

    func testFormatWithSymbolBtc() {
        XCTAssertEqual(
            "0.00000001 BTC",
            btcFormatter.format(value: CryptoValue.bitcoin(satoshis: 1), withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.1 BTC",
            btcFormatter.format(value: CryptoValue.create(major: "0.1", currency: .bitcoin)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.0 BTC",
            btcFormatter.format(value: CryptoValue.create(major: "0", currency: .bitcoin)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1.0 BTC",
            btcFormatter.format(value: CryptoValue.create(major: "1", currency: .bitcoin)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1,000.0 BTC",
            btcFormatter.format(value: CryptoValue.create(major: "1000", currency: .bitcoin)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1,000,000.0 BTC",
            btcFormatter.format(value: CryptoValue.create(major: "1000000", currency: .bitcoin)!, withPrecision: .short, includeSymbol: true)
        )
    }

    func testFormatEthShortPrecision() {
        XCTAssertEqual(
            "0.0 ETH",
            ethFormatter.format(value: CryptoValue.ether(minor: "1")!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.0 ETH",
            ethFormatter.format(value: CryptoValue.ether(minor: "1000")!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.0 ETH",
            ethFormatter.format(value: CryptoValue.ether(minor: "1000000")!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.0 ETH",
            ethFormatter.format(value: CryptoValue.ether(minor: "1000000000")!, withPrecision: .short, includeSymbol: true)
        )
    }

    func testFormatEthLongPrecision() {
        XCTAssertEqual(
            "0.000000000000000001 ETH",
            ethFormatter.format(value: CryptoValue.ether(minor: "1")!, withPrecision: .long, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.000000000000001 ETH",
            ethFormatter.format(value: CryptoValue.ether(minor: "1000")!, withPrecision: .long, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.000000000001 ETH",
            ethFormatter.format(value: CryptoValue.ether(minor: "1000000")!, withPrecision: .long, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.000000001 ETH",
            ethFormatter.format(value: CryptoValue.ether(minor: "1000000000")!, withPrecision: .long, includeSymbol: true)
        )
    }

    func testFormatWithoutSymbolEth() {
        XCTAssertEqual(
            "0.00000001",
            ethFormatter.format(value: CryptoValue.ether(minor: "10000000000")!)
        )
        XCTAssertEqual(
            "0.00001",
            ethFormatter.format(value: CryptoValue.ether(minor: "10000000000000")!)
        )
        XCTAssertEqual(
            "0.1",
            ethFormatter.format(value: CryptoValue.ether(minor: "100000000000000000")!)
        )
        XCTAssertEqual(
            "1.0",
            ethFormatter.format(value: CryptoValue.ether(minor: "1000000000000000000")!)
        )
        XCTAssertEqual(
            "10.0",
            ethFormatter.format(value: CryptoValue.ether(minor: "10000000000000000000")!)
        )
        XCTAssertEqual(
            "100.0",
            ethFormatter.format(value: CryptoValue.ether(minor: "100000000000000000000")!)
        )
        XCTAssertEqual(
            "1,000.0",
            ethFormatter.format(value: CryptoValue.ether(minor: "1000000000000000000000")!)
        )
        XCTAssertEqual(
            "1.213333",
            ethFormatter.format(value: CryptoValue.ether(major: "1.213333")!)
        )
        XCTAssertEqual(
            "1.12345678",
            ethFormatter.format(value: CryptoValue.ether(major: "1.123456789")!)
        )
    }

    func testFormatWithSymbolEth() {
        XCTAssertEqual(
            "0.00000001 ETH",
            ethFormatter.format(value: CryptoValue.ether(minor: "10000000000")!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.00001 ETH",
            ethFormatter.format(value: CryptoValue.ether(minor: "10000000000000")!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.1 ETH",
            ethFormatter.format(value: CryptoValue.ether(minor: "100000000000000000")!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1.213333 ETH",
            ethFormatter.format(value: CryptoValue.ether(major: "1.213333")!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1.12345678 ETH",
            ethFormatter.format(value: CryptoValue.ether(major: "1.123456789")!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1.12345678 ETH",
            ethFormatter.format(value: CryptoValue.ether(minor: "1123456789333222111")!, withPrecision: .short, includeSymbol: true)
        )
    }

    func testFormatWithoutSymbolBch() {
        XCTAssertEqual(
            "0.00000001",
            bchFormatter.format(value: CryptoValue.bitcoin(satoshis: 1))
        )
        XCTAssertEqual(
            "0.1",
            bchFormatter.format(value: CryptoValue.create(major: "0.1", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "0.0",
            bchFormatter.format(value: CryptoValue.create(major: "0", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1.0",
            bchFormatter.format(value: CryptoValue.create(major: "1", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1,000.0",
            bchFormatter.format(value: CryptoValue.create(major: "1000", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1,000,000.0",
            bchFormatter.format(value: CryptoValue.create(major: "1000000", currency: .bitcoin)!)
        )
    }

    func testFormatWithSymbolBch() {
        XCTAssertEqual(
            "0.00000001 BCH",
            bchFormatter.format(value: CryptoValue.bitcoinCash(satoshis: 1), withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.1 BCH",
            bchFormatter.format(value: CryptoValue.create(major: "0.1", currency: .bitcoinCash)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.0 BCH",
            bchFormatter.format(value: CryptoValue.create(major: "0", currency: .bitcoinCash)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1.0 BCH",
            bchFormatter.format(value: CryptoValue.create(major: "1", currency: .bitcoinCash)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1,000.0 BCH",
            bchFormatter.format(value: CryptoValue.create(major: "1000", currency: .bitcoinCash)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1,000,000.0 BCH",
            bchFormatter.format(value: CryptoValue.create(major: "1000000", currency: .bitcoinCash)!, withPrecision: .short, includeSymbol: true)
        )
    }

    func testFormatWithoutSymbolXlm() {
        XCTAssertEqual(
            "0.0000001",
            xlmFormatter.format(value: CryptoValue.stellar(minor: 1))
        )
        XCTAssertEqual(
            "0.1",
            xlmFormatter.format(value: CryptoValue.stellar(major: "\(Decimal(0.1))")!)
        )
        XCTAssertEqual(
            "0.0",
            xlmFormatter.format(value: CryptoValue.stellar(major: "\(Decimal(0))")!)
        )
        XCTAssertEqual(
            "1.0",
            xlmFormatter.format(value: CryptoValue.stellar(major: "\(Decimal(1))")!)
        )
        XCTAssertEqual(
            "1,000.0",
            xlmFormatter.format(value: CryptoValue.stellar(major: 1_000))
        )
        XCTAssertEqual(
            "1,000,000.0",
            xlmFormatter.format(value: CryptoValue.stellar(major: 1_000_000))
        )
    }

    func testFormatWithSymbolXlm() {
        XCTAssertEqual(
            "0.0000001 XLM",
            xlmFormatter.format(value: CryptoValue.stellar(minor: 1), withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.1 XLM",
            xlmFormatter.format(value: CryptoValue.stellar(major: "\(Decimal(0.1))")!,
                                withPrecision: .short,
                                includeSymbol: true)
        )
        XCTAssertEqual(
            "0.0 XLM",
            xlmFormatter.format(value: CryptoValue.stellar(major: "\(Decimal(0))")!,
                                withPrecision: .short,
                                includeSymbol: true)
        )
        XCTAssertEqual(
            "1.0 XLM",
            xlmFormatter.format(value: CryptoValue.stellar(major: "\(Decimal(1))")!,
                                withPrecision: .short,
                                includeSymbol: true)
        )
        XCTAssertEqual(
            "1,000.0 XLM",
            xlmFormatter.format(value: CryptoValue.stellar(major: 1_000), withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1,000,000.0 XLM",
            xlmFormatter.format(value: CryptoValue.stellar(major: 1_000_000), withPrecision: .short, includeSymbol: true)
        )
    }

    func testItalyLocaleFormattingBtc() {
        let italyLocale = Locale(identifier: "it_IT")
        let formatter = CryptoFormatter(locale: italyLocale, cryptoCurrency: .bitcoin)
        XCTAssertEqual(
            "0,00000001",
            formatter.format(value: CryptoValue.bitcoin(satoshis: 1))
        )
        XCTAssertEqual(
            "0,1",
            formatter.format(value: CryptoValue.create(major: "0.1", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "0,0",
            formatter.format(value: CryptoValue.create(major: "0", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1,0",
            formatter.format(value: CryptoValue.create(major: "1", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1.000,0",
            formatter.format(value: CryptoValue.create(major: "1000", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1.000.000,0",
            formatter.format(value: CryptoValue.create(major: "1000000", currency: .bitcoin)!)
        )
    }
}
