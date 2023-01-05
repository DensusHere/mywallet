// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Combine
import FeatureProductsDomain

// Observer used for high risk countries. Using the products API to determine if the user should be defaulted to a certain mode.

public final class DefaultAppModeObserver: Client.Observer {
    let app: AppProtocol
    let productsService: FeatureProductsDomain.ProductsServiceAPI
    private var cancellables: Set<AnyCancellable> = []

    public init(
        app: AppProtocol,
        productsService: FeatureProductsDomain.ProductsServiceAPI
    ) {
        self.app = app
        self.productsService = productsService
    }

    var observers: [BlockchainEventSubscription] {
        [
            userDidUpdate
        ]
    }

    public func start() {
        for observer in observers {
            observer.start()
        }
    }

    public func stop() {
        for observer in observers {
            observer.stop()
        }
    }

    lazy var userDidUpdate = app.on(blockchain.user.event.did.update) { [weak self] _ in
        guard let self else { return }
        Task { [productsService = self.productsService, app = self.app] in
            async let useTradingAccountProduct = try? await productsService
                .fetchProducts()
                .await()
                .filter { $0.id == ProductIdentifier.useTradingAccount }
                .first

            let hasBeenDefaultedAlready = (try? app.state.get(blockchain.app.mode.has.been.force.defaulted.to.mode, as: AppMode.self) == AppMode.pkw) ?? false
            guard hasBeenDefaultedAlready == false,
                  let useTradingAccountProduct = await useTradingAccountProduct,
                  useTradingAccountProduct.defaultProduct == false || useTradingAccountProduct.enabled == false
            else {
                return
            }
           app.post(value: AppMode.pkw.rawValue, of: blockchain.app.mode)
           app.post(value: AppMode.pkw.rawValue, of: blockchain.app.mode.has.been.force.defaulted.to.mode)
        }
    }
}
