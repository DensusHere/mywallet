// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import Combine
import ComposableArchitecture
import DIKit
import Extensions
import FeatureProveDomain
import Foundation
import SwiftUI

public final class ProveRouter: ProveRouterAPI {
    private let completionSubject = PassthroughSubject<VerificationResult, Never>()
    private let topViewController: TopMostViewControllerProviding
    private let app: AppProtocol

    enum Step {
        case beginProve(proveConfig: ProveConfig)
        case enterInfo(phone: String?, proveConfig: ProveConfig)
        case confirmInfo(prefillInfo: PrefillInfo, proveConfig: ProveConfig)
        case verificationSuccess
    }

    public init(
        topViewController: TopMostViewControllerProviding,
        app: AppProtocol = resolve()
    ) {
        self.topViewController = topViewController
        self.app = app
    }

    public func presentFlow(
        proveConfig: ProveConfig
    ) -> PassthroughSubject<VerificationResult, Never> {
        Task {
            do {
                app.state.set(blockchain.ux.pin.is.disabled, to: true)
                await MainActor.run {
                    let navigationViewController = UINavigationController(
                        rootViewController: self.view(step: .beginProve(proveConfig: proveConfig))
                    )
                    navigationViewController.isModalInPresentation = true
                    topViewController
                        .topMostViewController?
                        .present(navigationViewController, animated: true)
                }
            }
        }
        return completionSubject
    }

    func goToStep(_ step: Step) {
        topViewController
            .topMostViewController?
            .navigationController?
            .pushViewController(
                view(step: step),
                animated: true
            )
    }

    func onFailed(result: VerificationResult.Failure = .generic) {
        exitFlow(result: .failure(result))
    }

    func onSkip() {
        exitFlow(result: .abandoned)
    }

    func onDone() {
        exitFlow(result: .success)
    }

    private func exitFlow(result: VerificationResult) {
        topViewController
            .topMostViewController?
            .dismiss(animated: true, completion: { [weak self] in
                self?.app.state.set(blockchain.ux.pin.is.disabled, to: false)
                self?.completionSubject.send(result)
            })
    }

    private func endFlow() {
        completionSubject.send(.success)
        topViewController
            .topMostViewController?
            .dismiss(animated: true)
    }

    func view(step: Step) -> UIViewController {
        switch step {
        case .beginProve(let proveConfig):
            let view = BeginVerificationView(store: .init(
                initialState: .init(),
                reducer: BeginVerification(
                    app: app,
                    mobileAuthInfoService: resolve(),
                    dismissFlow: { [weak self] result in
                        switch result {
                        case .failure:
                            self?.onFailed()
                        case .abandoned:
                            self?.onSkip()
                        case .success(let mobileAuthInfo):
                            self?.goToStep(
                                .enterInfo(phone: mobileAuthInfo?.phone, proveConfig: proveConfig)
                            )
                        }
                    }
                )
            )).app(app)
            let viewController = UIHostingController(rootView: view)

            return viewController

        case let .enterInfo(phone, proveConfig):
            if let phone = phone {
                let reducer = EnterInformation(
                    app: app,
                    prefillInfoService: resolve(),
                    dismissFlow: { [weak self] result in
                        switch result {
                        case .failure:
                            self?.onFailed()
                        case .abandoned:
                            self?.onSkip()
                        case .success(let prefillInfo):
                            self?.goToStep(
                                .confirmInfo(prefillInfo: prefillInfo, proveConfig: proveConfig)
                            )
                        }
                    }
                )
                let store: StoreOf<EnterInformation> = .init(
                    initialState: .init(phone: phone),
                    reducer: reducer
                )
                let view = EnterInformationView(store: store).app(app)

                let viewController = UIHostingController(rootView: view)

                return viewController
            } else {
                let reducer = EnterFullInformation(
                    app: app,
                    mainQueue: .main,
                    phoneVerificationService: resolve(),
                    prefillInfoService: resolve(),
                    dismissFlow: { [weak self] result in
                        switch result {
                        case .failure:
                            self?.onFailed()
                        case .abandoned:
                            self?.onSkip()
                        case .success(let prefillInfo):
                            self?.goToStep(
                                .confirmInfo(prefillInfo: prefillInfo, proveConfig: proveConfig)
                            )
                        }
                    }
                )
                let store: StoreOf<EnterFullInformation> = .init(
                    initialState: .init(),
                    reducer: reducer
                )
                let view = EnterFullInformationView(store: store).app(app)

                let viewController = UIHostingController(rootView: view)

                return viewController
            }

        case let .confirmInfo(prefillInfo, proveConfig):
            let reducer = ConfirmInformation(
                app: app,
                mainQueue: .main,
                proveConfig: proveConfig,
                confirmInfoService: resolve(),
                addressSearchFlowPresenter: resolve(),
                dismissFlow: { [weak self] result in
                    switch result {
                    case .failure:
                        self?.onFailed(result: .verification)
                    case .abandoned:
                        self?.onSkip()
                    case .success:
                        self?.goToStep(.verificationSuccess)
                    }
                }
            )
            let store: StoreOf<ConfirmInformation> = .init(
                initialState: .init(
                    firstName: prefillInfo.firstName,
                    lastName: prefillInfo.lastName,
                    addresses: prefillInfo.validAddresses(
                        country: proveConfig.country, state: proveConfig.state
                    ),
                    selectedAddress: prefillInfo.addresses.first,
                    dateOfBirth: prefillInfo.dateOfBirth,
                    phone: prefillInfo.phone
                ),
                reducer: reducer
            )
            let view = ConfirmInformationView(store: store).app(app)

            let viewController = UIHostingController(rootView: view)

            return viewController

        case .verificationSuccess:
            let reducer = SuccessfullyVerified() { [weak self] in
                self?.onDone()
            }
            let store: StoreOf<SuccessfullyVerified> = .init(
                initialState: .init(),
                reducer: reducer
            )
            let view = SuccessfullyVerifiedView(store: store).app(app)

            let viewController = UIHostingController(rootView: view)

            return viewController
        }
    }
}
