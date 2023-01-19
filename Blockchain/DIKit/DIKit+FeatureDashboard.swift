// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureAppUI
import FeatureCoinDomain
import FeatureDashboardUI
import FeatureKYCUI
import FeatureSettingsDomain
import FeatureSettingsUI
import NetworkKit
import PlatformUIKit
import RxCocoa
import WalletPayloadKit

// MARK: - Blockchain Module

extension DependencyContainer {

    static var blockchainDashboard = module {

        factory { () -> FeatureDashboardUI.WalletOperationsRouting in
            let bridge: LoggedInDependencyBridgeAPI = DIKit.resolve()
            return bridge.resolveWalletOperationsRouting() as FeatureDashboardUI.WalletOperationsRouting
        }

        factory { AnnouncementPresenter() as FeatureDashboardUI.AnnouncementPresenting }

        factory { AnalyticsUserPropertyInteractor() as FeatureDashboardUI.AnalyticsUserPropertyInteracting }

        single { () -> PricesWatchlistRepositoryAPI in
            PricesWatchlistRepository(
                watchlistRepository: DIKit.resolve(),
                app: DIKit.resolve()
            )
        }
    }
}

extension AnalyticsUserPropertyInteractor: FeatureDashboardUI.AnalyticsUserPropertyInteracting {}

extension AnnouncementPresenter: FeatureDashboardUI.AnnouncementPresenting {}

final class PricesWatchlistRepository: PricesWatchlistRepositoryAPI {

    private var cancellables = Set<AnyCancellable>()
    private let subject: CurrentValueSubject<Set<String>?, NetworkError> = CurrentValueSubject([])

    init(
        watchlistRepository: WatchlistRepositoryAPI,
        app: AppProtocol
    ) {

        watchlistRepository.getWatchlist()
            .sink(receiveValue: subject.send(_:))
            .store(in: &cancellables)

        app.on(blockchain.ux.asset.watchlist.add).eraseError()
            .withLatestFrom(subject.eraseError(), selector: { ($0, $1) })
            .map { event, watchlist in
                if let code = try? event.reference.context.decode(blockchain.ux.asset.id) as String {
                    return watchlist?.union(Set([code]))
                }
                return watchlist
            }
            .sink(receiveValue: subject.send(_:))
            .store(in: &cancellables)

        app.on(blockchain.ux.asset.watchlist.remove).eraseError()
            .withLatestFrom(subject.eraseError(), selector: { ($0, $1) })
            .map { event, watchlist in
                var watchlist = watchlist
                if let code = try? event.reference.context.decode(blockchain.ux.asset.id) as String {
                    watchlist?.remove(code)
                }
                return watchlist
            }
            .sink(receiveValue: subject.send(_:))
            .store(in: &cancellables)
    }

    func watchlist() -> AnyPublisher<Result<Set<String>?, Error>, Never> {
        subject.eraseError().result()
    }
}
