// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureAuthenticationDomain
import PlatformKit
import Sift
import ToolKit

final class SiftService: FeatureAuthenticationDomain.SiftServiceAPI, PlatformKit.SiftServiceAPI {

    private enum Constants {
        static let siftAccountId = "siftAccountId"
        static let siftKey = "siftKey"
    }

    // MARK: - Private properties

    private var sift: AnyPublisher<Sift?, Never> {
        featureFetcher
            .isEnabled(.siftScienceEnabled)
            .map { isEnabled in
                isEnabled ? Sift.sharedInstance() : nil
            }
            .eraseToAnyPublisher()
    }

    private var identifier: String {
        guard let accountId = infoDictionary[Constants.siftAccountId] as? String else {
            return ""
        }
        return accountId
    }

    private var beacon: String {
        guard let accountId = infoDictionary[Constants.siftKey] as? String else {
            return ""
        }
        return accountId
    }

    private var infoDictionary: [String: Any] {
        guard let infoDictionary = MainBundleProvider.mainBundle.infoDictionary else {
            return [:]
        }
        return infoDictionary
    }

    private var bag = Set<AnyCancellable>()
    private let featureFetcher: FeatureFlagsServiceAPI

    init(featureFetcher: FeatureFlagsServiceAPI = DIKit.resolve()) {
        self.featureFetcher = featureFetcher
    }

    // MARK: - SiftServiceAPI

    /// Enables the services
    func enable() {
        sift
            .sink(receiveValue: { [identifier, beacon] sift in
                sift?.accountId = identifier
                sift?.beaconKey = beacon
                sift?.allowUsingMotionSensors = false
                sift?.disallowCollectingLocationData = true
            })
            .store(in: &bag)
    }

    func set(userId: String) {
        sift
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { sift in
                sift?.userId = userId
            })
            .store(in: &bag)
    }

    func removeUserId() {
        sift
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { sift in
                sift?.unsetUserId()
            })
            .store(in: &bag)
    }
}
