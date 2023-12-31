// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Errors
import Foundation

public protocol AnnouncementsServiceAPI {
    func fetchMessages(for modes: [Announcement.AppMode], force: Bool) async throws -> [Announcement]
    func setRead(announcement: Announcement) -> AnyPublisher<Void, NabuNetworkError>
    func setTapped(announcement: Announcement) -> AnyPublisher<Void, NabuNetworkError>
    func setDismissed(
        _ announcement: Announcement,
        with action: Announcement.Action
    ) -> AnyPublisher<Void, NabuNetworkError>
    func handle(_ announcement: Announcement) -> AnyPublisher<Void, Never>
}

extension AnnouncementsServiceAPI {
    public func fetchMessages(for modes: [Announcement.AppMode]) async throws -> [Announcement] {
        try await fetchMessages(for: modes, force: false)
    }
}
