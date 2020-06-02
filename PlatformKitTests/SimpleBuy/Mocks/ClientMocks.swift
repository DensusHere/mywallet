//
//  ClientMocks.swift
//  PlatformKitTests
//
//  Created by Daniel Huri on 14/02/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

@testable import PlatformKit

extension SimpleBuyClient {

    static func mockPaymentAccountResponse(for currency: FiatCurrency = .GBP) -> SimpleBuyPaymentAccountResponse {
        let mockAgent = SimpleBuyPaymentAccountResponse.Agent(
            account: "123456987",
            address: "4250 Executive Square, La Jolla, California, 92037",
            code: "LHVBEE22",
            country: "Estonia",
            name: "LHV",
            recipient: "Fred Wilson",
            routingNumber: "123456987"
        )
        return SimpleBuyPaymentAccountResponse(
            id: "12-34-56-78",
            address: "4250 Executive Square, La Jolla, California, 92037",
            agent: mockAgent,
            currency: currency,
            state: .pending
        )
    }

    static var paymentMethods: SimpleBuyPaymentMethodsResponse {
        SimpleBuyPaymentMethodsResponse(
            currency: "GBP",
            methods: [
                .init(
                    type: "BANK_TRANSFER",
                    limits: .init(min: "5000", max: "200000"),
                    subTypes: []
                ),
                .init(
                    type: "CARD",
                    limits: .init(min: "5000", max: "500000"),
                    subTypes: []
                )
            ]
        )
    }
    
    private static var cardList: [CardPayload] {
        [
            CardPayload(
                identifier: "a4e4c08d-b9e4-443d-b54e-47a3d2886dcf",
                partner: .everyPay,
                address: .init(
                    line1: "18 Golders Green Circle",
                    line2: "Flat 1",
                    postCode: "NW11 1EQ",
                    city: "London",
                    state: nil,
                    country: "United Kingdom"
                ),
                currency: "GBP",
                state: .active,
                card: .init(
                    number: "1234",
                    month: "10",
                    year: "2021",
                    type: "VISA",
                    label: "Visa Card 1234"
                ),
                additionDate: "2020-04-07T23:23:26.761Z"
            )
        ]
    }
    
    static func mockQuote(for action: SimpleBuyOrder.Action,
                          to cryptoCurrency: CryptoCurrency,
                          amount: FiatValue) -> SimpleBuyQuoteResponse {
        return SimpleBuyQuoteResponse(
            time: "2020-01-15T22:09:45.600Z",
            rate: "1000000",
            rateWithoutFee: "995000",
            fee: "5000"
        )
    }

    static func mockOrderCreation(order: SimpleBuyOrderPayload.Request) -> SimpleBuyOrderPayload.Response {
        return .init(
            state: "PENDING_DEPOSIT",
            id: UUID().uuidString,
            inputCurrency: order.input.symbol,
            inputQuantity: order.input.amount,
            outputCurrency: order.output.symbol,
            outputQuantity: "100000",
            updatedAt: "2020-01-01T12:20:42.849Z",
            expiresAt: "2020-01-01T12:20:42.849Z",
            price: "0",
            fee: "0",
            paymentMethodId: nil,
            attributes: nil
        )
    }

    static var mockOrdersDetails: [SimpleBuyOrderPayload.Response] {
        [
            SimpleBuyOrderPayload.Response(
                state: SimpleBuyOrderDetails.State.pendingDeposit.rawValue,
                id: "111111-aaaaaaaa-111111",
                inputCurrency: FiatCurrency.GBP.code,
                inputQuantity: "10000",
                outputCurrency: CryptoCurrency.ethereum.code,
                outputQuantity: "100000",
                updatedAt: "2020-01-01T12:20:42.849Z",
                expiresAt: "2020-01-01T12:20:42.849Z",
                price: "0",
                fee: "0",
                paymentMethodId: nil,
                attributes: nil
            )
        ]
    }

    static func mockSupportedPairs(currency: FiatCurrency) -> SimpleBuySupportedPairsResponse {
        SimpleBuySupportedPairsResponse(
            pairs: [
                SimpleBuySupportedPairsResponse.Pair(
                    pair: "BTC-\(currency.code)",
                    buyMin: "1000",
                    buyMax: "100000"
                ),
                SimpleBuySupportedPairsResponse.Pair(
                    pair: "BTC-\(currency.code)",
                    buyMin: "1000",
                    buyMax: "100000"
                ),
                SimpleBuySupportedPairsResponse.Pair(
                    pair: "BCH-\(currency.code)",
                    buyMin: "1000",
                    buyMax: "100000"
                ),
                SimpleBuySupportedPairsResponse.Pair(
                    pair: "ETH-\(currency.code)",
                    buyMin: "100",
                    buyMax: "10000"
                )
            ]
        )
    }
}
