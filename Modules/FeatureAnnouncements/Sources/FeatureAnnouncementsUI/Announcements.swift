import Blockchain
import Combine
import ComposableArchitecture
import Errors
import FeatureAnnouncementsDomain
import Foundation

public struct Announcements: ReducerProtocol {

    public enum LoadingStatus: Equatable {
        case idle
        case loading
        case loaded
    }

    // MARK: - Types

    public struct State: Equatable {
        public var status: LoadingStatus = .idle
        public var announcements: [Announcement] = []
        public var showCompletion: Bool = false
        public var initialized: Bool = false

        public init() {}
    }

    public enum Action: Equatable {
        case initialize
        case fetchAnnouncements(Bool)
        case open(Announcement)
        case read(Announcement?)
        case dismiss(Announcement, Announcement.Action)
        case delete(Announcement)
        case onAnnouncementsFetched([Announcement])
        case hideCompletion
    }

    // MARK: - Properties

    private let app: AppProtocol
    private let services: [AnnouncementsServiceAPI]
    private let mainQueue: AnySchedulerOf<DispatchQueue>
    private let mode: Announcement.AppMode

    // MARK: - Setup

    public init (
        app: AppProtocol,
        mainQueue: AnySchedulerOf<DispatchQueue>,
        mode: Announcement.AppMode,
        services: [AnnouncementsServiceAPI]
    ) {
        self.app = app
        self.mainQueue = mainQueue
        self.services = services
        self.mode = mode
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .initialize:
            guard state.status == .idle, !state.initialized else {
                return .none
            }
            state.initialized = true
            return .merge(
                EffectTask(value: .fetchAnnouncements(false)),
                app
                    .on(blockchain.ux.home.event.did.pull.to.refresh)
                    .map { _ in Action.fetchAnnouncements(true) }
                    .debounce(for: .seconds(1), scheduler: mainQueue)
                    .receive(on: mainQueue)
                    .eraseToEffect()
            )
        case .fetchAnnouncements(let force):
            guard state.status != .loading else {
                return .none
            }
            state.status = .loading
            return .run { send in
                let announcements = try await withThrowingTaskGroup(of: [Announcement].self) { group in
                    services.forEach { service in
                        group.addTask {
                            await (try? service.fetchMessages(for: [mode, .universal], force: force)) ?? []
                        }
                    }

                    var collected = [Announcement]()
                    for try await value in group {
                        collected.append(contentsOf: value)
                    }
                    return collected
                }
                await send(.onAnnouncementsFetched(announcements))
            }
        case .open(let announcement):
            return Publishers.MergeMany(services.map { service in service.handle(announcement) })
                .collect()
                .map { _ in Action.dismiss(announcement, .open) }
                .receive(on: mainQueue)
                .eraseToEffect()
        case .read(let announcement):
            guard let announcement, !announcement.read else {
                return .none
            }
            return Publishers.MergeMany(services.map { service in service.setRead(announcement: announcement) })
                .collect()
                .receive(on: mainQueue)
                .eraseToEffect()
                .fireAndForget()
        case .dismiss(let announcement, let action):
            return .merge(
                Publishers.MergeMany(services.map { service in service.setDismissed(announcement, with: action) })
                    .collect()
                    .receive(on: mainQueue)
                    .eraseToEffect()
                    .fireAndForget(),
                EffectTask(value: .read(state.announcements.last)),
                EffectTask(value: .delete(announcement))
            )
        case .delete(let announcement):
            state.announcements = state.announcements.filter { $0 != announcement }
            state.showCompletion = state.announcements.isEmpty
            return .none
        case .onAnnouncementsFetched(let announcements):
            state.status = .loaded
            state.announcements = announcements.sorted().reversed()
            return EffectTask(value: .read(announcements.last))
        case .hideCompletion:
            state.showCompletion = false
            return .none
        }
    }
}
