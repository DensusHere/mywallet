//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.

import Combine
import ComposableArchitecture
import ComposableArchitectureExtensions
import DIKit
import FeatureCoinDomain
import FeatureCoinUI
import FeatureDashboardUI
import PlatformUIKit
import SwiftUI
import ToolKit

struct PricesView: UIViewControllerRepresentable {

    let store: Store<Void, RootViewAction>

    init(store: Store<Void, RootViewAction>) {
        self.store = store
    }

    private var featureFlagService: FeatureFlagsServiceAPI = resolve()

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}

    func makeUIViewController(context: Context) -> some UIViewController {
        let presenter = PricesScreenPresenter(
            drawerRouter: NoDrawer(),
            interactor: PricesScreenInteractor(
                showSupportedPairsOnly: false
            )
        )
        let viewController = PricesViewController(
            presenter: presenter,
            featureFlagService: featureFlagService,
            presentRedesignCoinView: { _, cryptoCurrency in
                ViewStore(store).send(.enter(into: .coinView(cryptoCurrency)))
            }
        )
        viewController.automaticallyApplyNavigationBarStyle = false
        return viewController
    }
}

class NoDrawer: DrawerRouting {
    func toggleSideMenu() {}
    func closeSideMenu() {}
}
