// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import BlockchainNamespace
import Combine
import DIKit
import Errors
import FeatureFormDomain
import FeatureKYCDomain
import Localization
import ToolKit
import UIComponentsKit
import UIKit

final class KYCAccountUsageController: KYCBaseViewController {

    private var isBlocking: Bool = true
    private var cancellables = Set<AnyCancellable>()

    override class func make(with coordinator: KYCRouter) -> KYCBaseViewController {
        let controller = KYCAccountUsageController()
        controller.pageType = .accountUsageForm
        controller.router = coordinator
        return controller
    }

    let app: AppProtocol = DIKit.resolve()
    let analyticsRecorder: AnalyticsEventRecorderAPI = DIKit.resolve()
    let accountUsageService: KYCAccountUsageServiceAPI = DIKit.resolve()

    override func viewDidLoad() {
        super.viewDidLoad()
        embedAccountUsageView()
        title = LocalizationConstants.NewKYC.Steps.AccountUsage.title
    }

    private func embedAccountUsageView() {
        let publisher = app.publisher(for: blockchain.ux.kyc.extra.questions.form.data)
            .compactMap { data in data.value as? Result<FeatureFormDomain.Form, Nabu.Error> }
            .get()
            .prefix(1)
            .eraseToAnyPublisher()
        let view = AccountUsageView(
            store: .init(
                initialState: AccountUsage.State.idle,
                reducer: AccountUsage.reducer,
                environment: AccountUsage.Environment(
                    onComplete: continueToNextStep,
                    dismiss: dismissWithAnimation,
                    loadForm: { publisher },
                    submitForm: accountUsageService.submitExtraKYCQuestions,
                    analyticsRecorder: analyticsRecorder
                )
            )
        )
        _ = publisher
            .map(\.blocking)
            .replaceError(with: false)
            .assign(to: \.isBlocking, on: self)
        embed(view)
    }

    private func continueToNextStep() {
        router.handle(event: .nextPageFromPageType(pageType, nil))
    }

    @objc private func dismissWithAnimation() {
        app.state.clear(blockchain.ux.kyc.extra.questions.form)
        dismiss(animated: true)
    }

    override func navControllerRightBarButtonTapped(_ navController: KYCOnboardingNavigationController) {
        // default handler navifation tap handler
        // define var as handler return default
        switch navControllerCTAType() {
        case .none, .help:
            break
        case .skip:
            continueToNextStep()
        case .dismiss:
            app.state.clear(blockchain.ux.kyc.extra.questions.form)
            dismiss(animated: true)
        }
    }

    // MARK: - UI Configuration

    override func navControllerCTAType() -> NavigationCTA {
        if isBlocking {
            return .dismiss
        } else {
            return .skip
        }
    }
}
