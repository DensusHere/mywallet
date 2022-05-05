// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import Embrace
import FeatureCoinData
import FeatureCoinDomain
import FeatureOpenBankingUI
import FeatureQRCodeScannerDomain
import FeatureSettingsUI
import FeatureTransactionUI
import ObservabilityDomain
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
                accountsRouter: {
                    DIKit.resolve()
                }
            )
        }

        factory {
            CardIssuingAdapter(
                cardIssuingBuilder: DIKit.resolve(),
                nabuUserService: DIKit.resolve()
            ) as FeatureSettingsUI.CardIssuingViewControllerAPI
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
    }
}