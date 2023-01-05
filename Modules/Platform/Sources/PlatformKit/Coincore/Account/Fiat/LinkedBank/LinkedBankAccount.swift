// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import MoneyKit
import RxSwift
import ToolKit

public class LinkedBankAccount: FiatAccount, BankAccount {

    // MARK: - BlockchainAccount

    public let accountType: AccountType = .external
    public let isDefault: Bool = false

    public var actionableBalance: AnyPublisher<MoneyValue, Error> {
        .just(.zero(currency: fiatCurrency))
    }

    public var sourceState: Single<SourceState> {
        .just(.canTransact)
    }

    public var canWithdrawFunds: Single<Bool> {
        .just(false)
    }

    public var receiveAddress: AnyPublisher<ReceiveAddress, Error> {
        .just(
            BankAccountReceiveAddress(
                address: accountId,
                label: label,
                currencyType: currencyType
            )
        )
    }

    public var balance: AnyPublisher<MoneyValue, Error> {
        .just(.zero(currency: fiatCurrency))
    }

    public var pendingBalance: AnyPublisher<MoneyValue, Error> {
        .just(.zero(currency: fiatCurrency))
    }

    public var isFunded: AnyPublisher<Bool, Error> {
        .just(false)
    }

    public var activity: AnyPublisher<[ActivityItemEvent], Error> {
        .just([])
    }

    public let fiatCurrency: FiatCurrency
    public private(set) lazy var identifier: AnyHashable = "LinkedBankAccount.\(accountId).\(accountNumber).\(paymentType)"

    public let label: String
    public let accountId: String
    public let accountNumber: String
    public let bankAccountType: LinkedBankAccountType
    public let paymentType: PaymentMethodPayloadType
    public let partner: LinkedBankData.Partner
    public let data: LinkedBankData

    // MARK: - Init

    public init(
        label: String,
        accountNumber: String,
        accountId: String,
        bankAccountType: LinkedBankAccountType,
        currency: FiatCurrency,
        paymentType: PaymentMethodPayloadType,
        partner: LinkedBankData.Partner,
        data: LinkedBankData
    ) {
        self.label = label
        self.accountId = accountId
        self.bankAccountType = bankAccountType
        self.accountNumber = accountNumber
        self.fiatCurrency = currency
        self.paymentType = paymentType
        self.partner = partner
        self.data = data
    }

    // MARK: - BlockchainAccount

    public func can(perform action: AssetAction) -> AnyPublisher<Bool, Error> {
        .just(false)
    }

    public func invalidateAccountBalance() {
        // no-op
    }

    public func balancePair(
        fiatCurrency: FiatCurrency,
        at time: PriceTime
    ) -> AnyPublisher<MoneyValuePair, Error> {
        .just(.zero(baseCurrency: currencyType, quoteCurrency: fiatCurrency.currencyType))
    }

    public func mainBalanceToDisplayPair(
        fiatCurrency: FiatCurrency,
        at time: PriceTime
    ) -> AnyPublisher<MoneyValuePair, Error> {
        .just(.zero(baseCurrency: currencyType, quoteCurrency: fiatCurrency.currencyType))
    }
}
