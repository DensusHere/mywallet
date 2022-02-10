// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import EthereumKit
@testable import MoneyKit
@testable import MoneyKitMock
import XCTest

final class EIP681URITests: XCTestCase {

    enum TestCase {
        static let address = "0xfb6916095ca1df60bb79Ce92ce3ea74c37c5d359"
        static let contract = "0xfb6916095ca1df60bb79Ce92ce3ea74c37c5d359"
        static let sendString = "ethereum:\(address)@33?value=2.014e18&gasPrice=10&gasLimit=20"
        static let transferString = "ethereum:\(contract)@33/transfer?address=\(address)&uint256=1"
    }

    var enabledCurrenciesService: MockEnabledCurrenciesService!
    let currency: CryptoCurrency = .erc20(
        .mockERC20(
            name: "ERC20 1",
            erc20Address: TestCase.contract,
            sortIndex: 0
        )
    )

    override func setUp() {
        super.setUp()
        enabledCurrenciesService = MockEnabledCurrenciesService()
        enabledCurrenciesService.allEnabledCryptoCurrencies.append(
            currency
        )
    }

    override func tearDown() {
        super.tearDown()
        enabledCurrenciesService = nil
    }

    func testDecodeSend() {
        let eip681URI = EIP681URI(
            url: TestCase.sendString,
            enabledCurrenciesService: enabledCurrenciesService
        )
        XCTAssertNotNil(eip681URI)
        XCTAssertEqual(eip681URI?.address, TestCase.address)
        XCTAssertEqual(eip681URI?.cryptoCurrency, .coin(.ethereum))
        XCTAssertEqual(
            eip681URI?.method,
            .send(
                amount: .create(major: "2.014", currency: .coin(.ethereum)),
                gasLimit: 20,
                gasPrice: 10
            )
        )
    }

    func testDecodeTransfer() {
        let eip681URI = EIP681URI(
            url: TestCase.transferString,
            enabledCurrenciesService: enabledCurrenciesService
        )
        XCTAssertNotNil(eip681URI)
        XCTAssertEqual(eip681URI?.address, TestCase.contract)
        XCTAssertEqual(eip681URI?.cryptoCurrency, currency)
        XCTAssertEqual(
            eip681URI?.method,
            .transfer(
                destination: TestCase.address,
                amount: .create(minor: 1, currency: currency)
            )
        )
    }
}
