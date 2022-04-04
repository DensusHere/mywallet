// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Combine
import FeatureActivityUI
import FeatureDashboardUI
import FeatureTransactionDomain
import FeatureTransactionUI
import MoneyKit
import PlatformKit
import PlatformUIKit
import SwiftUI
import UIComponentsKit
import UIKit

public final class DeepLinkCoordinator: Session.Observer {

    private let app: AppProtocol
    private let coincore: CoincoreAPI
    private let exchangeProvider: ExchangeProviding
    private let kycRouter: KYCRouting
    private let payloadFactory: CryptoTargetPayloadFactoryAPI
    private let topMostViewControllerProvider: TopMostViewControllerProviding
    private let transactionsRouter: TransactionsRouterAPI

    private var bag: Set<AnyCancellable> = []

    // We can't resolve those at initialization
    private let accountsRouter: () -> AccountsRouting

    init(
        app: AppProtocol,
        coincore: CoincoreAPI,
        exchangeProvider: ExchangeProviding,
        kycRouter: KYCRouting,
        payloadFactory: CryptoTargetPayloadFactoryAPI,
        topMostViewControllerProvider: TopMostViewControllerProviding,
        transactionsRouter: TransactionsRouterAPI,
        accountsRouter: @escaping () -> AccountsRouting
    ) {
        self.accountsRouter = accountsRouter
        self.app = app
        self.coincore = coincore
        self.exchangeProvider = exchangeProvider
        self.kycRouter = kycRouter
        self.payloadFactory = payloadFactory
        self.topMostViewControllerProvider = topMostViewControllerProvider
        self.transactionsRouter = transactionsRouter
    }

    var observers: [AnyCancellable] {
        [
            activity,
            buy,
            asset,
            qr,
            send,
            kyc
        ]
    }

    public func start() {
        for observer in observers {
            observer.store(in: &bag)
        }
    }

    public func stop() {
        bag = []
    }

    private lazy var activity = app.on(blockchain.app.deep_link.activity)
        .receive(on: DispatchQueue.main)
        .sink(to: DeepLinkCoordinator.showActivity(_:), on: self)

    private lazy var buy = app.on(blockchain.app.deep_link.buy)
        .receive(on: DispatchQueue.main)
        .sink(to: DeepLinkCoordinator.showTransactionBuy(_:), on: self)

    private lazy var send = app.on(blockchain.app.deep_link.send)
        .receive(on: DispatchQueue.main)
        .sink(to: DeepLinkCoordinator.showTransactionSend(_:), on: self)

    private lazy var asset = app.on(blockchain.app.deep_link.asset)
        .flatMap { [unowned self] event -> AnyPublisher<(Session.Event, Bool), Never> in
            app.publisher(for: blockchain.app.configuration.redesign.coinview, as: Bool.self)
                .compactMap(\.value)
                .prefix(1)
                .map { (event, $0) }
                .eraseToAnyPublisher()
        }
        .receive(on: DispatchQueue.main)
        .sink(to: DeepLinkCoordinator.showAsset, on: self)

    private lazy var qr = app.on(blockchain.app.deep_link.qr)
        .receive(on: DispatchQueue.main)
        .sink(to: DeepLinkCoordinator.qr(_:), on: self)

    private lazy var kyc = app.on(blockchain.app.deep_link.kyc)
        .receive(on: DispatchQueue.main)
        .sink(to: DeepLinkCoordinator.kyc(_:), on: self)

    func kyc(_ event: Session.Event) {
        guard let tier = try? event.context.decode(blockchain.app.deep_link.kyc.tier, as: KYC.Tier.self),
              let topViewController = topMostViewControllerProvider.topMostViewController
        else {
            return
        }

        kycRouter
            .presentEmailVerificationAndKYCIfNeeded(from: topViewController, requiredTier: tier)
            .subscribe()
            .store(in: &bag)
    }

    func qr(_ event: Session.Event) {
        let qrCodeScannerView = QRCodeScannerView()
        topMostViewControllerProvider
            .topMostViewController?
            .present(qrCodeScannerView)
    }

    func showAsset(_ event: Session.Event, isRedesignEnabled: Bool) {

        let cryptoCurrency = (
            try? event.context.decode(blockchain.app.deep_link.asset.code) as CryptoCurrency
        ) ?? .bitcoin

        if isRedesignEnabled {
            let navigationController = UINavigationController()
            navigationController.setViewControllers(
                [
                    UIHostingController(
                        rootView: CoinAdapterView(
                            cryptoCurrency: cryptoCurrency,
                            app: app,
                            dismiss: { [weak navigationController] in
                                navigationController?.dismiss(animated: true)
                            }
                        )
                    )
                ],
                animated: false
            )
            topMostViewControllerProvider.topMostViewController?.present(navigationController, animated: true)
        } else {

            let builder = AssetDetailsBuilder(
                accountsRouter: accountsRouter(),
                currency: cryptoCurrency,
                exchangeProviding: exchangeProvider
            )
            let controller = builder.build()
            topMostViewControllerProvider.topMostViewController?.present(controller, animated: true)
        }
    }

    func showTransactionBuy(_ event: Session.Event) {
        do {
            let cryptoCurrency = try event.context.decode(blockchain.app.deep_link.buy.crypto.code) as CryptoCurrency
            coincore
                .cryptoAccounts(for: cryptoCurrency)
                .receive(on: DispatchQueue.main)
                .flatMap { [weak self] accounts -> AnyPublisher<TransactionFlowResult, Never> in
                    guard let self = self else {
                        return .just(.abandoned)
                    }
                    return self
                        .transactionsRouter
                        .presentTransactionFlow(to: .buy(accounts.first))
                }
                .subscribe()
                .store(in: &bag)
        } catch {
            transactionsRouter.presentTransactionFlow(to: .buy(nil))
                .subscribe()
                .store(in: &bag)
        }
    }

    func showTransactionSend(_ event: Session.Event) {

        // If there is no crypto currency, show landing send.
        guard let cryptoCurrency = try? event.context.decode(
            blockchain.app.deep_link.send.crypto.code,
            as: CryptoCurrency.self
        ) else {
            showTransactionSendLanding()
            return
        }

        showTransactionSend(
            cryptoCurrency: cryptoCurrency,
            destination: try? event.context.decode(
                blockchain.app.deep_link.send.destination,
                as: String.self
            )
        )
    }

    private func showTransactionSendLanding() {
        transactionsRouter
            .presentTransactionFlow(to: .send(nil, nil))
            .subscribe()
            .store(in: &bag)
    }

    private func showTransactionSend(
        cryptoCurrency: CryptoCurrency,
        destination: String?
    ) {
        let defaultAccount = coincore.cryptoAccounts(for: cryptoCurrency)
            .map(\.first)
            .eraseError()
        let target = transactionTarget(
            from: destination,
            cryptoCurrency: cryptoCurrency
        )
        .optional()
        .replaceError(with: nil)
        .eraseError()

        defaultAccount
            .zip(target)
            .receive(on: DispatchQueue.main)
            .flatMap { [weak self] defaultAccount, target -> AnyPublisher<TransactionFlowResult, Never> in
                guard let self = self else {
                    return .just(.abandoned)
                }
                return self
                    .transactionsRouter
                    .presentTransactionFlow(to: .send(defaultAccount, target))
            }
            .subscribe()
            .store(in: &bag)
    }

    /// Creates transaction target from given string.
    private func transactionTarget(
        from string: String?,
        cryptoCurrency: CryptoCurrency
    ) -> AnyPublisher<CryptoReceiveAddress, Error> {
        payloadFactory
            .create(fromString: string, asset: cryptoCurrency)
            .eraseError()
            .flatMap { target -> AnyPublisher<CryptoReceiveAddress, Error> in
                switch target {
                case .bitpay(let address):
                    return BitPayInvoiceTarget
                        .make(from: address, asset: cryptoCurrency)
                        .map { $0 as CryptoReceiveAddress }
                        .eraseError()
                        .eraseToAnyPublisher()
                case .address(let cryptoReceiveAddress):
                    return .just(cryptoReceiveAddress)
                }
            }
            .eraseToAnyPublisher()
    }

    func showActivity(_ event: Session.Event) {
        app.post(event: blockchain.ux.home.tab[blockchain.ux.user.activity].select)
    }
}
