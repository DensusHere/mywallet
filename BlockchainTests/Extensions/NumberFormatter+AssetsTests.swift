// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import BlockchainApp
import XCTest

class NumberFormatterAssetsTests: XCTestCase {

    let localCurrencyDecimalPlaces = 2
    let assetDecimalPlaces = 8

    let groupingAssertFormat = "Strings returned from %@ should have grouping separators"
    let noGroupingAssertFormat = "Strings returned from %@ should not have grouping separators"
    let decimalAssertFormat = "String returned from %@ should have %d decimal places"

    typealias ExpectDecimal = (expected: Int, assertStatement: String)
    typealias ExpectGrouping = (expect: Bool, assertStatement: String)

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testLocalCurrencyFormatterWithGroupingSeparator() {
        // Setup test
        let name = "localCurrencyFormatterWithGroupingSeparator"
        let decimalTuple = expectDecimalPlaces(expected: localCurrencyDecimalPlaces, functionName: name)

        let testStringFromNumber = { (input: NSNumber, groupingTuple: ExpectGrouping) -> Void in
            self.testFormatter(
                formatter: NumberFormatter.localCurrencyFormatterWithGroupingSeparator,
                inputAmount: input,
                grouping: groupingTuple,
                decimalPlaces: decimalTuple
            )
        }

        let grouping = expectGrouping(expect: true, functionName: name)
        let noGrouping = expectGrouping(expect: false, functionName: name)

        // Execute Tests
        testStringFromNumber(1234.56, grouping)
        testStringFromNumber(123.45, noGrouping)
        testStringFromNumber(123.456, noGrouping)
        testStringFromNumber(1.0, noGrouping)
        testStringFromNumber(0, noGrouping)
    }

    func testBitcoinFormatterWithGroupingSeparator() {
        let name = "bitcoinFormatterWithGroupingSeparator"
        let testStringFromNumber = { (input: NSNumber, groupingTuple: ExpectGrouping, decimalTuple: ExpectDecimal) -> Void in
            self.testFormatter(
                formatter: NumberFormatter.bitcoinFormatterWithGroupingSeparator,
                inputAmount: input,
                grouping: groupingTuple,
                decimalPlaces: decimalTuple
            )
        }

        let grouping = expectGrouping(expect: true, functionName: name)
        let noGrouping = expectGrouping(expect: false, functionName: name)
        let decimals = { (expected: Int) -> ExpectDecimal in self.expectDecimalPlaces(expected: expected, functionName: name) }

        // Execute tests
        testStringFromNumber(1234.12345678, grouping, decimals(8))
        testStringFromNumber(1234.123456, grouping, decimals(6))
        testStringFromNumber(1234.1234, grouping, decimals(4))
        testStringFromNumber(1234.1, grouping, decimals(1))
        testStringFromNumber(1234, grouping, decimals(0))
        testStringFromNumber(123.1234, noGrouping, decimals(4))
        testStringFromNumber(0, noGrouping, decimals(0))
    }

    // MARK: Helpers

    private func testFormatter(
        formatter: NumberFormatter,
        inputAmount: NSNumber,
        grouping: ExpectGrouping,
        decimalPlaces: ExpectDecimal
    ) {
        let formatted = testNumberFormatterOutput(formatter: formatter, inputAmount: inputAmount)
        let groupingSeparator = testNumberFormatterGroupingSeparator(formatter: formatter, inputAmount: inputAmount)

        // Check for grouping separators
        let hasGroupingSeparator = formatted.contains(groupingSeparator)
        XCTAssert(
            (hasGroupingSeparator && grouping.expect) ||
                (!hasGroupingSeparator && !grouping.expect),
            grouping.assertStatement
        )

        // Check for decimal places
        guard let decimalSeparator = formatter.locale.decimalSeparator else {
            XCTFail("Could not get decimal separator from formatter")
            return
        }
        let numbersAfterDecimal = testNumberFormatterNumbersAfterDecimal(
            formatted: formatted,
            inputAmount: inputAmount,
            decimalSeparator: decimalSeparator
        )
        XCTAssert(numbersAfterDecimal == decimalPlaces.expected, decimalPlaces.assertStatement)
    }

    private func testNumberFormatterOutput(formatter: NumberFormatter, inputAmount: NSNumber) -> String {
        guard let formatted = formatter.string(from: inputAmount) else {
            XCTFail("Could not get formatted string from formatter")
            return ""
        }
        return formatted
    }

    private func testNumberFormatterGroupingSeparator(formatter: NumberFormatter, inputAmount: NSNumber) -> String {
        guard let groupingSeparator = formatter.locale.groupingSeparator else {
            XCTFail("Could not get grouping separator from formatter")
            return ""
        }
        return groupingSeparator
    }

    private func testNumberFormatterNumbersAfterDecimal(formatted: String, inputAmount: NSNumber, decimalSeparator: String) -> Int {
        if !formatted.contains(decimalSeparator) {
            return 0
        }
        let components = formatted.components(separatedBy: decimalSeparator)
        if components.count == 2 {
            guard let numbersAfterDecimal = formatted.components(separatedBy: decimalSeparator).last else {
                XCTFail("Could not get numbers after decimal from formatter")
                return 0
            }
            return numbersAfterDecimal.count
        }
        XCTFail("Unhandled decimal input")
        return 0
    }

    private func expectGrouping(expect: Bool, functionName: String) -> ExpectGrouping {
        (expect, String(format: expect ? groupingAssertFormat : noGroupingAssertFormat, functionName))
    }

    private func expectDecimalPlaces(expected: Int, functionName: String) -> ExpectDecimal {
        (expected, String(format: decimalAssertFormat, functionName, expected))
    }

    private func testUSLocaleFormatter(formatter: NumberFormatter, input: NSNumber) {
        guard let decimalSeparator = formatter.locale.decimalSeparator else {
            XCTFail("Could not get decimal separator from formatter")
            return
        }
        guard let output = formatter.string(from: input) else {
            XCTFail("Could not get string from formatter")
            return
        }
        if output.contains(decimalSeparator) {
            XCTAssert(decimalSeparator == ".")
        }
    }
}
