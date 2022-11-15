// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Combine
import DIKit
import Foundation

public final class UserTagObserver: Client.Observer {
    let app: AppProtocol
    let userTagSyncService: UserTagServiceAPI
    private var cancellables: Set<AnyCancellable> = []

    public init(
        app: AppProtocol,
        userTagSyncService: UserTagServiceAPI
    ) {
        self.app = app
        self.userTagSyncService = userTagSyncService
    }

    var observers: [BlockchainEventSubscription] {
        [
            userDidSignIn
        ]
    }

    public func start() {
        for observer in observers {
            observer.start()
        }
    }

    public func stop() {
        for observer in observers {
            observer.stop()
        }
    }

    lazy var userDidSignIn = app.on(blockchain.user.event.did.update) { [weak self] _ in
        guard let self else { return }
        self.syncSuperAppUserTags()
    }

    private func syncSuperAppUserTags() {
        Task {
            let tagServiceIsEnabled = try await self.app.get(blockchain.api.nabu.gateway.user.tag.service.is.enabled, as: Bool.self)
            guard tagServiceIsEnabled else {
                return
            }
            let superAppTag = try? await self.app.get(blockchain.user.is.superapp.user, as: Bool?.self)
            let superAppEnabled = try await self.app.get(blockchain.app.configuration.app.superapp.is.enabled, as: Bool.self)
            if superAppTag != superAppEnabled {
                try? await self.userTagSyncService.updateSuperAppTag(isEnabled: superAppEnabled).await()
            }
        }
    }
}
