// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import FeatureNotificationPreferencesDomain
import Foundation
import NetworkError

public struct NotificationPreferencesRepository: NotificationPreferencesRepositoryAPI {
    private let client: NotificationPreferencesClient

    public init(client: NotificationPreferencesClient) {
        self.client = client
    }

    public func fetchPreferences() -> AnyPublisher<[NotificationPreference], NetworkError> {
        client
            .fetchPreferences()
            .map { response in
                let availableMethods = response.notificationMethods

                return response
                    .preferences
                    .map { $0.toNotificationPreference(with: availableMethods) }
            }
            .eraseToAnyPublisher()
    }

    public func update(preferences: UpdatedPreferences) -> AnyPublisher<Void, NetworkError> {
        client
            .update(preferences)
            .eraseToAnyPublisher()
    }
}

extension NotificationMethodInfoResponse {
    public func toNotificationMethodInfo() -> NotificationMethodInfo {
        NotificationMethodInfo(id: UUID(), method: method, title: title, configured: configured, verified: verified)
    }
}

extension NotificationPreferenceResponse {
    public func toNotificationPreference(with
        availableMethods: [NotificationMethodInfoResponse]) -> NotificationPreference
    {

        let requiredMethods: [NotificationMethodInfo] = requiredMethods
            .compactMap { currentMethod in
                availableMethods.first(where: { $0.method == currentMethod })?.toNotificationMethodInfo()
            }

        let optionalMethods: [NotificationMethodInfo] = optionalMethods
            .compactMap { currentMethod in
                availableMethods.first(where: { $0.method == currentMethod })?.toNotificationMethodInfo()
            }

        let enabledMethods: [NotificationMethodInfo] = enabledMethods
            .compactMap { currentMethod in
                availableMethods.first(where: { $0.method == currentMethod })?.toNotificationMethodInfo()
            }

        return NotificationPreference(
            id: UUID(),
            type: type,
            title: title,
            subtitle: subtitle,
            preferenceDescription: description,
            requiredMethods: requiredMethods,
            optionalMethods: optionalMethods,
            enabledMethods: enabledMethods
        )
    }
}
