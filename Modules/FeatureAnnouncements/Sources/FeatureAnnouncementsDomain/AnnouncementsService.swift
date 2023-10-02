// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Blockchain
import Combine
import Errors
import Foundation

public final class AnnouncementsService: AnnouncementsServiceAPI {

    private let app: AppProtocol
    private let repository: AnnouncementsRepositoryAPI

    public init(
        app: AppProtocol,
        repository: AnnouncementsRepositoryAPI
    ) {
        self.app = app
        self.repository = repository
    }

    public func fetchMessages(for modes: [Announcement.AppMode], force: Bool) async throws -> [Announcement] {
        do {
            return try await repository
                .fetchMessages(force: force)
                .map { announcements in
                    announcements.filter { announcement in
                        modes.contains(announcement.content.appMode)
                    }
                }
                .await()
        } catch {
            throw error
        }
    }

    public func setRead(announcement: Announcement) -> AnyPublisher<Void, Errors.NabuNetworkError> {
        repository.setRead(announcement: announcement)
    }

    public func setTapped(announcement: Announcement) -> AnyPublisher<Void, Errors.NabuNetworkError> {
        repository.setTapped(announcement: announcement)
    }

    public func setDismissed(_ announcement: Announcement, with action: Announcement.Action) -> AnyPublisher<Void, Errors.NabuNetworkError> {
        repository.setDismissed(announcement, with: action)
    }

    public func handle(_ announcement: Announcement) -> AnyPublisher<Void, Never> {
        repository
            .fetchMessages(force: false)
            .catch { _ in
                []
            }
            .flatMap { [weak self] messages -> AnyPublisher<Void, Never> in
                guard let self else {
                    return .just(())
                }

                if messages.contains(announcement) {
                    app.post(
                        event: blockchain.ux.dashboard.announcements.open.paragraph.button.primary.tap.then.launch.url,
                        context: [
                            blockchain.ui.type.action.then.launch.url: announcement.content.actionUrl
                        ]
                    )
                }

                return setTapped(announcement: announcement)
                    .catch { _ in () }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
