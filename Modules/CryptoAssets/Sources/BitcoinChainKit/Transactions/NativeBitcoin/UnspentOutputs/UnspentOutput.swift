// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BigInt
import MoneyKit
import PlatformKit
import ToolKit
import WalletCore

public struct UnspentOutput: Equatable {

    public struct XPub: Equatable {
        /// An xpub.
        public let m: String
        /// A derivation path in the format "M/X/Y", relative to the xpub `m`.
        public let path: String

        public init(m: String, path: String) {
            self.m = m
            self.path = path
        }
    }

    public var magnitude: BigUInt {
        value.amount.magnitude
    }

    public let confirmations: UInt
    public let hash: String
    public let hashBigEndian: String
    public let outputIndex: Int
    public let script: String
    public let transactionIndex: Int
    public let value: CryptoValue
    public let xpub: XPub

    public init(
        confirmations: UInt,
        hash: String,
        hashBigEndian: String,
        outputIndex: Int,
        script: String,
        transactionIndex: Int,
        value: CryptoValue,
        xpub: UnspentOutput.XPub
    ) {
        self.confirmations = confirmations
        self.hash = hash
        self.hashBigEndian = hashBigEndian
        self.outputIndex = outputIndex
        self.script = script
        self.transactionIndex = transactionIndex
        self.value = value
        self.xpub = xpub
    }
}

extension UnspentOutput {
    public var scriptType: BitcoinScriptType {
        guard let script = BitcoinScriptType(scriptData: Data(hex: script)) else {
            fatalError("Misconfigured")
        }
        return script
    }

    var isSegwit: Bool {
        guard case .P2WPKH = scriptType else {
            return false
        }
        return true
    }
}

extension UnspentOutput {
    init(response: UnspentOutputResponse, coin: BitcoinChainCoin) {
        confirmations = response.confirmations
        hash = response.tx_hash
        hashBigEndian = response.tx_hash_big_endian
        outputIndex = response.tx_output_n
        script = response.script
        transactionIndex = response.tx_index
        value = CryptoValue.create(minor: response.value, currency: coin.cryptoCurrency)
        xpub = XPub(responseXPub: response.xpub)
    }
}

extension UnspentOutput.XPub {
    init(responseXPub: UnspentOutputResponse.XPub) {
        m = responseXPub.m
        path = responseXPub.path
    }
}

extension UnspentOutput {

    /// Calculate the effective value of the coin, that is the value minus the fee that takes to add this coin as input.
    /// ceil(value - cost(type) * fee)
    func effectiveValue(fee feePerByte: BigUInt) -> BigUInt {
        let feePerByte = feePerByte.decimal
        let cost = feePerByte * TransactionCost.PerInput.for(scriptType)
        let value = magnitude.decimal
        let effectiveValue = (value - cost).roundTo(places: 0, roundingMode: .up)
        guard effectiveValue > 0 else {
            return .zero
        }
        return BigUInt((effectiveValue as NSDecimalNumber).stringValue)!
    }
}

extension Array where Element == UnspentOutput {
    func sum() -> BigUInt {
        guard !isEmpty else {
            return BigUInt.zero
        }
        return map(\.magnitude)
            .reduce(BigUInt.zero) { value, acc -> BigUInt in
                value + acc
            }
    }

    func effective(fee feePerByte: BigUInt) -> [UnspentOutput] {
        filter { $0.effectiveValue(fee: feePerByte) > BigUInt.zero }
    }
}
