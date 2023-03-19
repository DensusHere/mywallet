// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Combine
import DIKit

/// An in-memory cache implementation.
public final class InDiskCache<AKey: Hashable & CustomStringConvertible, Value: Equatable & Codable>: CacheAPI {
    public typealias Key = AKey

    private let appDatabase: AppDatabase

    private let refreshControl: CacheRefreshControl

    private var cancellables = Set<AnyCancellable>()

    public let source: (file: String, line: Int)

    private let enableAsyncWrites: Bool

    // MARK: - Setup

    /// Creates an in-memory cache.
    ///
    /// - Parameters:
    ///   - configuration:  A cache configuration.
    ///   - refreshControl: A cache refresh control.
    public convenience init(
        id: String,
        configuration: CacheConfiguration,
        refreshControl: CacheRefreshControl,
        notificationCenter: NotificationCenter = .default,
        enableAsyncWrites: Bool = false,
        file: String = #fileID,
        defaultApp: () -> AppProtocol = { DIKit.resolve() },
        line: Int = #line
    ) {
        var isInTest: Bool { NSClassFromString("XCTestCase") != nil }
        self.init(
            appDatabase: AppDatabase.makeShared(id: id, reset: false),
            configuration: configuration,
            refreshControl: refreshControl,
            notificationCenter: notificationCenter,
            app: isInTest ? App.preview : defaultApp(),
            enableAsyncWrites: enableAsyncWrites,
            file: file,
            line: line
        )
    }

    /// Creates an in-memory cache.
    ///
    /// - Parameters:
    ///   - configuration:  A cache configuration.
    ///   - refreshControl: A cache refresh control.
    init(
        appDatabase: AppDatabase,
        configuration: CacheConfiguration,
        refreshControl: CacheRefreshControl,
        notificationCenter: NotificationCenter = .default,
        app: AppProtocol,
        enableAsyncWrites: Bool = false,
        file: String = #fileID,
        line: Int = #line
    ) {
        self.appDatabase = appDatabase
        self.refreshControl = refreshControl
        self.source = (file, line)
        self.enableAsyncWrites = enableAsyncWrites
        
        for flushNotificationName in configuration.flushNotificationNames {
            notificationCenter
                .publisher(for: flushNotificationName)
                .sink { [weak self] _ in self?.flush() }
                .store(in: &cancellables)
        }

        for flush in configuration.flushEvents {
            switch flush {
            case .notification(let event):
                app.on(event)
                    .sink { [weak self] _ in self?.flush() }
                    .store(in: &cancellables)
            case .binding(let event):
                app.publisher(for: event)
                    .sink { [weak self] _ in _ = self?.flush() }
                    .store(in: &cancellables)
            }
        }
    }

    public func get(key: Key) -> AnyPublisher<CacheValue<Value>, Never> {
        Deferred { [appDatabase, toCacheValue] () -> AnyPublisher<CacheValue<Value>, Never> in
            let cacheItem = try? appDatabase.dbReader
                .read(InDiskEntityRequest<Value>(id: key.description).fetchValue)
            let cacheValue = toCacheValue(cacheItem)
            return .just(cacheValue)
        }
        .eraseToAnyPublisher()
    }

    public func stream(key: Key) -> AnyPublisher<CacheValue<Value>, Never> {
        InDiskEntityRequest<Value>(id: key.description)
            .publisher(in: appDatabase)
            .subscribe(on: DispatchQueue.main)
            .removeDuplicates()
            .map(toCacheValue)
            .share()
            .replaceError(with: .absent)
            .eraseToAnyPublisher()
    }

    public func set(_ value: Value, for key: Key) -> AnyPublisher<Value?, Never> {
        Deferred { [appDatabase, enableAsyncWrites] () -> AnyPublisher<Value?, Never> in
            let oldItem = try? appDatabase.dbReader
                .read(InDiskEntityRequest<Value>(id: key.description).fetchValue)
            let entity = InDiskEntity(id: key.description, value: value, lastRefresh: Date())
            do {
                if enableAsyncWrites {
                    appDatabase.dbWriter.asyncWrite({ db in
                        try entity.save(db)
                    }) { _, result in
                        print("db write: ", result)
                    }
                } else {
                    try appDatabase.dbWriter.write { db in
                        try entity.save(db)
                    }
                }
            } catch {
                print("error: \(error)")
            }
            return .just(oldItem?.first?.value)
        }
        .eraseToAnyPublisher()
    }

    public func remove(key: Key) -> AnyPublisher<Value?, Never> {
        Deferred { [appDatabase] () -> AnyPublisher<Value?, Never> in
            let oldItem = try? appDatabase.dbReader
                .read(InDiskEntityRequest<Value>(id: key.description).fetchValue)
            let entity = oldItem?.first
            try? appDatabase.dbWriter.write { db in
                _ = try? entity?.delete(db)
            }
            return .just(entity?.value)
        }
        .eraseToAnyPublisher()
    }

    public func removeAll() -> AnyPublisher<Void, Never> {
        Deferred { [appDatabase] () -> AnyPublisher<Void, Never> in
            .just(appDatabase.deleteAll())
        }
        .eraseToAnyPublisher()
    }

    private func flush() {
        refreshControl.invalidate()
    }

    // MARK: - Private Methods

    /// Maps the given cache item to a cache value.
    ///
    /// - Parameter cacheItem: A cache item.
    ///
    /// - Returns: A cache value.
    private func toCacheValue(_ cacheItem: [InDiskEntity<Value>]?) -> CacheValue<Value> {
        guard let item = cacheItem?.first else {
            return .absent
        }

        if refreshControl.shouldRefresh(lastRefresh: item.lastRefresh) {
            return .stale(item.value)
        }

        return .present(item.value)
    }
}
