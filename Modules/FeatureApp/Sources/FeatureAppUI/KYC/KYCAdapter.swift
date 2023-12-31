// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Blockchain
import Combine
import DIKit
import Errors
import FeatureAddressSearchDomain
import FeatureKYCDomain
import FeatureKYCUI
import FeatureOnboardingUI
import FeatureSettingsUI
import Localization
import PlatformKit
import PlatformUIKit
import RxSwift
import ToolKit
import UIComponentsKit
import UIKit

public final class KYCAdapter {

    // MARK: - Properties

    private let router: FeatureKYCUI.Routing

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(router: FeatureKYCUI.Routing = resolve()) {
        self.router = router
    }

    // MARK: - Public Interface

    public func presentEmailVerificationAndKYCIfNeeded(
        from presenter: UIViewController,
        requireEmailVerification: Bool,
        requiredTier: KYC.Tier
    ) -> AnyPublisher<FeatureKYCUI.FlowResult, FeatureKYCUI.RouterError> {
        router
            .presentEmailVerificationAndKYCIfNeeded(
                from: presenter,
                requireEmailVerification: requireEmailVerification,
                requiredTier: requiredTier
            )
            .eraseToAnyPublisher()
    }

    public func presentEmailVerificationIfNeeded(
        from presenter: UIViewController
    ) -> AnyPublisher<FeatureKYCUI.FlowResult, FeatureKYCUI.RouterError> {
        router
            .presentEmailVerificationIfNeeded(from: presenter)
            .eraseToAnyPublisher()
    }

    public func presentKYCIfNeeded(
        from presenter: UIViewController,
        requiredTier: KYC.Tier
    ) -> AnyPublisher<FeatureKYCUI.FlowResult, FeatureKYCUI.RouterError> {
        router
            .presentKYCIfNeeded(from: presenter, requiredTier: requiredTier)
            .eraseToAnyPublisher()
    }
}

extension KYCAdapter {

    public func presentKYCIfNeeded(
        from presenter: UIViewController,
        requireEmailVerification: Bool,
        requiredTier: KYC.Tier,
        completion: @escaping (FeatureKYCUI.FlowResult) -> Void
    ) {
        presentEmailVerificationAndKYCIfNeeded(
            from: presenter,
            requireEmailVerification: requireEmailVerification,
            requiredTier: requiredTier
        )
        .sink(receiveValue: completion)
        .store(in: &cancellables)
    }
}

// MARK: - PlatformUIKit.KYCRouting

extension KYCRouterError {

    public init(_ error: FeatureKYCUI.RouterError) {
        switch error {
        case .emailVerificationFailed:
            self = .emailVerificationFailed
        case .kycVerificationFailed:
            self = .kycVerificationFailed
        case .kycStepFailed:
            self = .kycStepFailed
        }
    }
}

extension KYCRoutingResult {

    public init(_ result: FeatureKYCUI.FlowResult) {
        switch result {
        case .abandoned:
            self = .abandoned
        case .completed:
            self = .completed
        case .skipped:
            self = .skipped
        }
    }
}

extension KYCAdapter: PlatformUIKit.KYCRouting {

    public func presentEmailVerificationAndKYCIfNeeded(
        from presenter: UIViewController,
        requiredTier: KYC.Tier
    ) -> AnyPublisher<KYCRoutingResult, KYCRouterError> {
        presentEmailVerificationAndKYCIfNeeded(
            from: presenter,
            requireEmailVerification: false,
            requiredTier: requiredTier
        )
        .mapError(KYCRouterError.init)
        .map(KYCRoutingResult.init)
        .eraseToAnyPublisher()
    }

    public func presentEmailVerificationIfNeeded(
        from presenter: UIViewController
    ) -> AnyPublisher<KYCRoutingResult, KYCRouterError> {
        presentEmailVerificationIfNeeded(from: presenter)
            .mapError(KYCRouterError.init)
            .map(KYCRoutingResult.init)
            .eraseToAnyPublisher()
    }

    public func presentKYCIfNeeded(
        from presenter: UIViewController,
        requiredTier: KYC.Tier
    ) -> AnyPublisher<KYCRoutingResult, KYCRouterError> {
        presentKYCIfNeeded(from: presenter, requiredTier: requiredTier)
            .mapError(KYCRouterError.init)
            .map(KYCRoutingResult.init)
            .eraseToAnyPublisher()
    }

    public func presentKYCUpgradeFlow(
        from presenter: UIViewController
    ) -> AnyPublisher<KYCRoutingResult, Never> {
        router.presentPromptToUnlockMoreTrading(from: presenter)
            .map(KYCRoutingResult.init)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public func presentKYCUpgradeFlowIfNeeded(
        from presenter: UIViewController,
        requiredTier: KYC.Tier
    ) -> AnyPublisher<KYCRoutingResult, KYCRouterError> {
        router.presentPromptToUnlockMoreTradingIfNeeded(from: presenter, requiredTier: requiredTier)
            .mapError(KYCRouterError.init)
            .map(KYCRoutingResult.init)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - FeatureOnboardingUI.KYCRouterAPI

extension OnboardingResult {

    public init(_ result: FeatureKYCUI.FlowResult) {
        switch result {
        case .abandoned:
            self = .abandoned
        case .completed:
            self = .completed
        case .skipped:
            self = .skipped
        }
    }
}

extension KYCAdapter: FeatureOnboardingUI.KYCRouterAPI {

    public func presentEmailVerification(from presenter: UIViewController) -> AnyPublisher<OnboardingResult, Never> {
        router.presentEmailVerificationIfNeeded(from: presenter)
            .map(OnboardingResult.init)
            .replaceError(with: OnboardingResult.skipped)
            .eraseToAnyPublisher()
    }
}

extension KYCAdapter: FeatureSettingsUI.KYCRouterAPI {

    public func presentLimitsOverview(from presenter: UIViewController) {
        router.presentLimitsOverview(from: presenter)
    }
}

final class AddressKYCService: FeatureAddressSearchDomain.AddressServiceAPI {
    typealias Address = FeatureAddressSearchDomain.Address

    private let locationUpdateService: LocationUpdateService

    init(locationUpdateService: LocationUpdateService = LocationUpdateService()) {
        self.locationUpdateService = locationUpdateService
    }

    func fetchAddress() -> AnyPublisher<Address?, AddressServiceError> {
        .just(nil)
    }

    func save(address: Address) -> AnyPublisher<Address, AddressServiceError> {
        guard let userAddress = UserAddress(address: address, countryCode: address.country) else {
            return .failure(AddressServiceError.network(Nabu.Error.unknown))
        }
        return locationUpdateService
            .save(address: userAddress)
            .map { address }
            .mapError(AddressServiceError.network)
            .eraseToAnyPublisher()
    }
}

extension UserAddressSearchResult {
    fileprivate init(addressResult: AddressResult) {
        switch addressResult {
        case .saved:
            self = .saved
        case .abandoned:
            self = .abandoned
        }
    }
}

extension UserAddress {
    fileprivate init?(
        address: FeatureAddressSearchDomain.Address,
        countryCode: String?
    ) {
        guard let countryCode else { return nil }
        self.init(
            lineOne: address.line1,
            lineTwo: address.line2,
            postalCode: address.postCode,
            city: address.city,
            state: address.state,
            countryCode: countryCode
        )
    }
}

extension FeatureAddressSearchDomain.Address {
    fileprivate init(
        address: UserAddress
    ) {
        self.init(
            line1: address.lineOne,
            line2: address.lineTwo,
            city: address.city,
            postCode: address.postalCode,
            state: address.state,
            country: address.countryCode
        )
    }
}

final class AddressSearchFlowPresenter: FeatureKYCUI.AddressSearchFlowPresenterAPI {

    private let addressSearchRouterRouter: FeatureAddressSearchDomain.AddressSearchRouterAPI

    init(
        addressSearchRouterRouter: FeatureAddressSearchDomain.AddressSearchRouterAPI
    ) {
        self.addressSearchRouterRouter = addressSearchRouterRouter
    }

    func openSearchAddressFlow(
        country: String,
        state: String?
    ) -> AnyPublisher<UserAddressSearchResult, Never> {
        typealias Localization = LocalizationConstants.NewKYC.AddressVerification
        return addressSearchRouterRouter.presentSearchAddressFlow(
            prefill: Address(state: state, country: country),
            config: .init(
                addressSearchScreen: .init(
                    title: Localization.title,
                    subtitle: Localization.subtitle
                ),
                addressEditScreen: .init(
                    title: Localization.title,
                    saveAddressButtonTitle: Localization.nextButtonTitle
                )
            )
        )
        .map { UserAddressSearchResult(addressResult: $0) }
        .eraseToAnyPublisher()
    }
}

public final class LaunchKYCClientObserver: Client.Observer {

    unowned let app: AppProtocol
    let router: FeatureKYCUI.Routing
    let window: TopMostViewControllerProviding

    public init(
        app: AppProtocol = resolve(),
        router: FeatureKYCUI.Routing = resolve(),
        window: TopMostViewControllerProviding = resolve()
    ) {
        self.app = app
        self.router = router
        self.window = window
    }

    private var subscription: AnyCancellable?

    public func start() {
        subscription = app.on(blockchain.ux.kyc.launch.verification)
            .receive(on: DispatchQueue.main)
            .map { [router, window] _ -> AnyPublisher<FeatureKYCUI.FlowResult, FeatureKYCUI.RouterError> in
                router.presentEmailVerificationAndKYCIfNeeded(from: window.findTopViewController(allowBeingDismissed: false), requireEmailVerification: true, requiredTier: .verified)
            }
            .switchToLatest()
            .subscribe()
    }

    public func stop() {
        subscription = nil
    }
}
