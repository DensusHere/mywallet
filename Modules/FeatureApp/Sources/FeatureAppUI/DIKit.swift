// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import Embrace
import FeatureAddressSearchDomain
import FeatureAddressSearchUI
import FeatureAuthenticationDomain
import FeatureCardIssuingDomain
import FeatureCardIssuingUI
import FeatureCoinData
import FeatureCoinDomain
import FeatureKYCDomain
import FeatureKYCUI
import FeatureOpenBankingUI
import FeatureProveDomain
import FeatureProveUI
import FeatureQRCodeScannerDomain
import FeatureSettingsUI
import FeatureTransactionUI
import ObservabilityKit
import PlatformKit
import PlatformUIKit
import ToolKit
import UIKit

extension DependencyContainer {

    public static var featureAppUI = module {

        single { BlurVisualEffectHandler() as BlurVisualEffectHandlerAPI }

        single { () -> BackgroundAppHandlerAPI in
            let timer = BackgroundTaskTimer(
                invalidBackgroundTaskIdentifier: BackgroundTaskIdentifier(
                    identifier: UIBackgroundTaskIdentifier.invalid
                )
            )
            return BackgroundAppHandler(backgroundTaskTimer: timer)
        }

        // MARK: Open Banking

        factory { () -> FeatureOpenBankingUI.FiatCurrencyFormatter in
            FiatCurrencyFormatter()
        }

        factory { () -> FeatureOpenBankingUI.CryptoCurrencyFormatter in
            CryptoCurrencyFormatter()
        }

        factory { LaunchOpenBankingFlow() as StartOpenBanking }

        // MARK: QR Code Scanner

        factory { () -> CryptoTargetQRCodeParserAdapter in
            QRCodeScannerAdapter(
                qrCodeScannerRouter: DIKit.resolve(),
                payloadFactory: DIKit.resolve(),
                topMostViewControllerProvider: DIKit.resolve(),
                navigationRouter: DIKit.resolve()
            )
        }

        factory { () -> QRCodeScannerLinkerAPI in
            QRCodeScannerAdapter(
                qrCodeScannerRouter: DIKit.resolve(),
                payloadFactory: DIKit.resolve(),
                topMostViewControllerProvider: DIKit.resolve(),
                navigationRouter: DIKit.resolve()
            )
        }

        single {
            DeepLinkCoordinator(
                app: DIKit.resolve(),
                coincore: DIKit.resolve(),
                exchangeProvider: DIKit.resolve(),
                kycRouter: DIKit.resolve(),
                payloadFactory: DIKit.resolve(),
                topMostViewControllerProvider: DIKit.resolve(),
                transactionsRouter: DIKit.resolve(),
                analyticsRecording: DIKit.resolve(),
                walletConnectService: { DIKit.resolve() },
                onboardingRouter: DIKit.resolve()
            )
        }

        factory {
            CardIssuingAddressProvider(
                nabuUserService: DIKit.resolve()
            ) as AddressProviderAPI
        }

        factory {
            CardIssuingAdapter(
                router: DIKit.resolve()
            ) as FeatureSettingsUI.CardIssuingRouterAPI
        }

        factory {
            CardIssuingTopUpRouter(
                coincore: DIKit.resolve(),
                transactionsRouter: DIKit.resolve()
            ) as TopUpRouterAPI
        }

        factory(tag: CardIssuingTag.residentialAddress) {
            CardIssuingAddressSearchRouter(
                addressSearchRouterRouter: DIKit.resolve(tag: CardIssuingTag.residentialAddress)
            ) as FeatureCardIssuingUI.AddressSearchRouterAPI
        }

        factory(tag: CardIssuingTag.shippingAddress) {
            CardIssuingAddressSearchRouter(
                addressSearchRouterRouter: DIKit.resolve(tag: CardIssuingTag.shippingAddress)
            ) as FeatureCardIssuingUI.AddressSearchRouterAPI
        }

        factory(tag: CardIssuingTag.residentialAddress) {
            AddressSearchRouter(
                topMostViewControllerProvider: DIKit.resolve(),
                addressService: DIKit.resolve(tag: CardIssuingTag.residentialAddress)
            ) as FeatureAddressSearchDomain.AddressSearchRouterAPI
        }

        factory(tag: CardIssuingTag.shippingAddress) {
            AddressSearchRouter(
                topMostViewControllerProvider: DIKit.resolve(),
                addressService: DIKit.resolve(tag: CardIssuingTag.shippingAddress)
            ) as FeatureAddressSearchDomain.AddressSearchRouterAPI
        }

        factory(tag: CardIssuingTag.residentialAddress) {
            AddressService(
                repository: DIKit.resolve(tag: CardIssuingTag.residentialAddress)
            ) as FeatureAddressSearchDomain.AddressServiceAPI
        }

        factory(tag: CardIssuingTag.shippingAddress) {
            AddressService(
                repository: DIKit.resolve(tag: CardIssuingTag.shippingAddress)
            ) as FeatureAddressSearchDomain.AddressServiceAPI
        }

        factory { () -> FeatureKYCUI.AddressSearchFlowPresenterAPI in
            AddressSearchFlowPresenterCardIssuingAdapter(
                addressSearchRouterRouter: DIKit.resolve()
            ) as FeatureKYCUI.AddressSearchFlowPresenterAPI
        }

        factory { () -> FeatureProveUI.AddressSearchFlowPresenterAPI in
            AddressSearchFlowPresenterProveAdapter(
                addressSearchRouterRouter: DIKit.resolve()
            ) as FeatureProveUI.AddressSearchFlowPresenterAPI
        }

        factory {
            AddressSearchRouter(
                topMostViewControllerProvider: DIKit.resolve(),
                addressService: DIKit.resolve()
            ) as FeatureAddressSearchDomain.AddressSearchRouterAPI
        }

        factory { () -> KYCProveFlowPresenterAPI in
            KYCProveFlowPresenter(
                router: DIKit.resolve()
            ) as KYCProveFlowPresenterAPI
        }

        factory {
            ProveRouter(
                topViewController: DIKit.resolve()
            ) as FeatureProveDomain.ProveRouterAPI
        }

        factory {
            AddressKYCService() as FeatureAddressSearchDomain.AddressServiceAPI
        }

        factory {
            FlowKYCInfoService() as FeatureKYCDomain.FlowKYCInfoServiceAPI
        }

        single { () -> AssetInformationRepositoryAPI in
            AssetInformationRepository(
                AssetInformationClient(
                    networkAdapter: DIKit.resolve(),
                    requestBuilder: DIKit.resolve()
                )
            )
        }

        factory { () -> ObservabilityServiceAPI in
            ObservabilityService(
                client: Embrace.sharedInstance()
            )
        }

        factory {
            CardIssuingAccountPickerAdapter(
                cardService: DIKit.resolve(),
                coinCore: DIKit.resolve(),
                fiatCurrencyService: DIKit.resolve(),
                nabuUserService: DIKit.resolve()
            ) as AccountProviderAPI
        }

        factory { UpdateSettingsClient(DIKit.resolve()) as UpdateSettingsClientAPI }
    }
}
