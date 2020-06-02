//
//  SimpleBuySuggestedAmounts.swift
//  PlatformKit
//
//  Created by Daniel Huri on 29/01/2020.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

public struct SimpleBuySuggestedAmounts {
    
    public subscript(currency: FiatCurrency) -> [FiatValue] {
        amountsPerCurrency[currency] ?? []
    }
    
    private let amountsPerCurrency: [FiatCurrency: [FiatValue]]

    init(response: SimpleBuySuggestedAmountsResponse) {
        amountsPerCurrency = response.amounts
            .reduce(into: [FiatCurrency: [FiatValue]]()) { result, element in
                guard let currency = FiatCurrency(code: element.key) else { return }
                result[currency] = element.value.map { FiatValue(minor: $0, currency: currency) }
            }
    }
}
