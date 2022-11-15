import AnalyticsKit
@_exported import BlockchainNamespace
import DIKit
import ErrorsUI
import FeatureAppUI
import FeatureAttributionDomain
import FeatureCoinUI
import FeatureCustomerSupportUI
import FeatureReferralDomain
import FeatureReferralUI
import FeatureUserTagSyncDomain
import FirebaseCore
import FirebaseInstallations
import FirebaseProtocol
import FirebaseRemoteConfig
import FraudIntelligence
import ObservabilityKit
import ToolKit
import UIKit

let app: AppProtocol = try! App(
    remoteConfiguration: Session.RemoteConfiguration(
        remote: FirebaseRemoteConfig.RemoteConfig.remoteConfig(),
        default: .init(blockchain.app.configuration.json(in: .main) as Any) + [
            blockchain.app.configuration.manual.login.is.enabled: BuildFlag.isInternal
        ]
    )
)

extension AppProtocol {

    func bootstrap(
        analytics recorder: AnalyticsEventRecorderAPI = resolve(),
        deepLink: DeepLinkCoordinator = resolve(),
        referralService: ReferralServiceAPI = resolve(),
        attributionService: AttributionServiceAPI = resolve(),
        performanceTracing: PerformanceTracingServiceAPI = resolve(),
        featureFlagService: FeatureFlagsServiceAPI = resolve(),
        userTagService: UserTagServiceAPI = resolve()
    ) {
        clientObservers.insert(ApplicationStateObserver(app: self))
        clientObservers.insert(AppHapticObserver(app: self))
        clientObservers.insert(AppAnalyticsObserver(app: self))
        clientObservers.insert(resolve() as AppAnalyticsTraitRepository)
        clientObservers.insert(KYCExtraQuestionsObserver(app: self))
        clientObservers.insert(NabuUserSessionObserver(app: self))
        clientObservers.insert(CoinViewAnalyticsObserver(app: self, analytics: recorder))
        clientObservers.insert(CoinViewObserver(app: self))
        clientObservers.insert(ReferralAppObserver(app: self, referralService: referralService))
        clientObservers.insert(AttributionAppObserver(app: self, attributionService: attributionService))
        clientObservers.insert(UserTagObserver(app: self, userTagSyncService: userTagService))
        clientObservers.insert(SuperAppIntroObserver(app: self))
        clientObservers.insert(EmbraceObserver(app: self))
        clientObservers.insert(GenerateSession(app: self))
        clientObservers.insert(PlaidLinkObserver(app: self))
        // observers.insert(EmbraceObserver(app: self))
        clientObservers.insert(deepLink)
        #if DEBUG || ALPHA_BUILD || INTERNAL_BUILD
        clientObservers.insert(PulseBlockchainNamespaceEventLogger(app: self))
        clientObservers.insert(MultiAppViewDebuggingObserver(app: self))
        #endif
        clientObservers.insert(PerformanceTracingObserver(app: self, service: performanceTracing))

        let intercom = (
            apiKey: Bundle.main.plist.intercomAPIKey[] as String?,
            appId: Bundle.main.plist.intercomAppId[] as String?
        )

        if let apiKey = intercom.apiKey, let appId = intercom.appId {
            clientObservers.insert(
                CustomerSupportObserver<Intercom>(
                    app: self,
                    apiKey: apiKey,
                    appId: appId,
                    open: UIApplication.shared.open,
                    unreadNotificationName: NSNotification.Name.IntercomUnreadConversationCountDidChange
                )
            )
        }

        #if canImport(MobileIntelligence)
        clientObservers.insert(Sardine<MobileIntelligence>(self))
        #endif

        Task {
            let result = try await Installations.installations().authTokenForcingRefresh(true)
            state.transaction { state in
                state.set(blockchain.user.token.firebase.installation, to: result.authToken)
            }
        }

        if state.doesNotContain(blockchain.ux.user.account.preferences.small.balances.are.hidden) {
            state.set(blockchain.ux.user.account.preferences.small.balances.are.hidden, to: true)
        }
    }
}

extension FirebaseRemoteConfig.RemoteConfig: RemoteConfiguration_p {}
extension FirebaseRemoteConfig.RemoteConfigValue: RemoteConfigurationValue_p {}
extension FirebaseRemoteConfig.RemoteConfigFetchStatus: RemoteConfigurationFetchStatus_p {}
extension FirebaseRemoteConfig.RemoteConfigSource: RemoteConfigurationSource_p {}

#if canImport(MobileIntelligence)
import class MobileIntelligence.MobileIntelligence
import struct MobileIntelligence.Options
import struct MobileIntelligence.Response
import struct MobileIntelligence.UpdateOptions

extension MobileIntelligence: MobileIntelligence_p {

    public static func start(_ options: Options) {
        MobileIntelligence(withOptions: options)
    }
}

extension Options: MobileIntelligenceOptions_p {}
extension Response: MobileIntelligenceResponse_p {}
extension UpdateOptions: MobileIntelligenceUpdateOptions_p {}

#endif

#if canImport(Intercom)
import class Intercom.ICMUserAttributes
import class Intercom.Intercom
extension Intercom: Intercom_p {}
extension ICMUserAttributes: IntercomUserAttributes_p {}
#endif

extension Tag.Event {

    fileprivate func json(in bundle: Bundle) -> Any? {
        guard let path = Bundle.main.path(forResource: description, ofType: "json") else { return nil }
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
    }
}
