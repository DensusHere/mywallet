// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnyCoding
import Combine
import Extensions
import FirebaseProtocol
import Foundation

extension Session {

    public class RemoteConfiguration {

        public var isSynchronized: Bool { _isSynchronized.value }
        private let _isSynchronized: CurrentValueSubject<Bool, Never> = .init(false)

        public var allKeys: [String] { Array(fetched.keys) }

        private var fetched: [String: Any?] {
            get { _decoded.value }
            set { _decoded.send(newValue) }
        }

        private var _fetched: PassthroughSubject<[String: Any?], Never> = .init()
        private var _decoded: CurrentValueSubject<[String: Any?], Never> = .init([:])

        private var fetch: ((AppProtocol, Bool) -> Void)?
        private var bag: Set<AnyCancellable> = []
        private let session: URLSessionProtocol
        private var preferences: Preferences
        private var experiments: Experiments!
        private unowned var app: AppProtocol!

        public init<Remote: RemoteConfiguration_p>(
            remote: Remote,
            session: URLSessionProtocol = URLSession.shared,
            preferences: Preferences = UserDefaults.standard,
            default defaultValue: Default = [:]
        ) {
            self.preferences = preferences
            self.session = session
            let backoff = ExponentialBackoff()
            fetch = { [unowned self] app, isStale in
                Task(priority: .high) {
                    let cached = preferences.object(
                        forKey: blockchain.session.configuration(\.id)
                    ) as? [String: Any] ?? [:]

                    var configuration: [String: Any?] = defaultValue.dictionary.mapKeys { key in
                        key.idToFirebaseConfigurationKeyDefault()
                    } + cached.mapKeys { important + $0 }

                    let expiration: TimeInterval
                    if isStale {
                        expiration = 0 // Instant
                    } else if isDebug {
                        expiration = 30 // 30 seconds
                    } else {
                        expiration = 3600 // 1 hour
                    }

                    do {
                        _ = try await remote.fetch(withExpirationDuration: expiration)
                        _ = try await remote.activate()
                    } catch {
                        print("😱", "unable to fetch remote configuration, retrying...", error)
                        try await backoff.next()
                        self.fetch?(app, isStale)
                    }

                    let keys = remote.allKeys(from: .remote)
                    for key in keys {
                        do {
                            configuration[key] = try JSONSerialization.jsonObject(
                                with: remote[key].dataValue,
                                options: .fragmentsAllowed
                            )
                        } catch {
                            configuration[key] = String(decoding: remote[key].dataValue, as: UTF8.self)
                        }
                    }
                    _fetched.send(configuration)
                    app.state.set(blockchain.app.configuration.remote.is.stale, to: false)
                }
            }

            _decoded.sink { configuration in
                let overrides = configuration
                    .filter { key, _ in key.starts(with: important) }
                    .mapKeys { key in
                        String(key.dropFirst())
                    }
                preferences.transaction(blockchain.session.configuration(\.id)) { object in
                    for (key, value) in overrides {
                        object[key] = value
                    }
                }
            }
            .store(in: &bag)
        }

        func start(app: AppProtocol) {

            self.app = app
            experiments = Experiments(app: app, session: session)

            app.publisher(for: blockchain.app.configuration.remote.is.stale, as: Bool.self)
                .replaceError(with: false)
                .scan((stale: false, count: 0)) { ($1, $0.count + 1) }
                .sink { [unowned self] stale, count in
                    if stale || count == 1 {
                        fetch?(app, stale)
                    }
                }
                .store(in: &bag)

            _fetched
                .flatMap(experiments.decode)
                .sink { [unowned self] output in
                    _decoded.send(output)
                    _isSynchronized.send(true)
                }
                .store(in: &bag)
        }

        private func key(_ event: Tag.Event) -> Tag.Reference {
            event.key().in(app)
        }

        public func contains(_ event: Tag.Event) -> Bool {
            fetched[firstOf: key(event).firebaseConfigurationKeys] != nil
        }

        public func override(_ event: Tag.Event, with value: Any) {
            fetched[key(event).idToFirebaseConfigurationKeyImportant()] = value
        }

        public func clear() {
            for (key, _) in fetched where key.hasPrefix(important) {
                fetched.removeValue(forKey: key)
            }
        }

        public func clear(_ event: Tag.Event) {
            fetched.removeValue(forKey: key(event).idToFirebaseConfigurationKeyImportant())
        }

        public func get(_ event: Tag.Event) throws -> Any? {
            let key = key(event)
            guard isSynchronized else { throw Error.notSynchronized }
            guard let value = fetched[firstOf: key.firebaseConfigurationKeys] else {
                throw Error.keyDoesNotExist(key)
            }
            return value
        }

        public func get<T: Decodable>(
            _ event: Tag.Event,
            as type: T.Type = T.self,
            using decoder: AnyDecoderProtocol = BlockchainNamespaceDecoder()
        ) throws -> T {
            try decoder.decode(T.self, from: get(event) as Any)
        }

        public func result(for event: Tag.Event) -> FetchResult {
            let key = key(event)
            guard isSynchronized else {
                return .error(.other(Error.notSynchronized), key.metadata(.remoteConfiguration))
            }
            guard let value = fetched[firstOf: key.firebaseConfigurationKeys] else {
                return .error(.keyDoesNotExist(key), key.metadata(.remoteConfiguration))
            }
            return .value(value as Any, key.metadata(.remoteConfiguration))
        }

        public func publisher(for event: Tag.Event) -> AnyPublisher<FetchResult, Never> {
            _isSynchronized
                .combineLatest(_decoded)
                .filter(\.0)
                .map(\.1)
                .flatMap { [key] configuration -> Just<FetchResult> in
                    let key = key(event)
                    switch configuration[firstOf: key.firebaseConfigurationKeys] {
                    case let value?:
                        return Just(.value(value as Any, key.metadata(.remoteConfiguration)))
                    case nil:
                        return Just(.error(.keyDoesNotExist(key), key.metadata(.remoteConfiguration)))
                    }
                }
                .eraseToAnyPublisher()
        }

        public func override(_ key: String, with value: Any) {
            fetched[key] = value
        }

        public func get(_ key: String) throws -> Any? {
            guard isSynchronized else { throw Error.notSynchronized }
            return fetched[key] as Any?
        }

        public func publisher(for string: String) -> AnyPublisher<Any?, Never> {
            _isSynchronized
                .combineLatest(_decoded)
                .filter(\.0)
                .map(\.1)
                .map { configuration -> Any? in configuration[string] as Any? }
                .eraseToAnyPublisher()
        }

        /// Determines if the app has the `DEBUG` build flag.
        private var isDebug: Bool {
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
    }
}

extension Session.RemoteConfiguration {

    @inlinable public func yes(
        if ifs: L & I_blockchain_db_type_boolean...,
        unless buts: L & I_blockchain_db_type_boolean...
    ) -> Bool {
        yes(if: ifs, unless: buts)
    }

    @inlinable public func yes(
        if ifs: [L & I_blockchain_db_type_boolean],
        unless buts: [L & I_blockchain_db_type_boolean]
    ) -> Bool {
        ifs.allSatisfy { result(for: $0).isYes } && buts.none { result(for: $0).isYes }
    }

    @inlinable public func no(
        if ifs: L & I_blockchain_db_type_boolean...,
        unless buts: L & I_blockchain_db_type_boolean...
    ) -> Bool {
        no(if: ifs, unless: buts)
    }

    @inlinable public func no(
        if ifs: [L & I_blockchain_db_type_boolean],
        unless buts: [L & I_blockchain_db_type_boolean]
    ) -> Bool {
        yes(if: ifs, unless: buts) ? false : true
    }
}

private let important: String = "!"

extension Session.RemoteConfiguration {

    public enum Error: Swift.Error {
        case notSynchronized
        case keyDoesNotExist(Tag.Reference)
    }
}

extension Tag.Reference {

    fileprivate var components: [String] {
        tag.lineage.reversed().flatMap { tag -> [String] in
            guard
                let collectionId = try? tag.as(blockchain.db.collection).id[],
                let id = indices[collectionId]
            else {
                return [tag.name]
            }
            return [tag.name, id.description]
        }
    }

    fileprivate var firebaseConfigurationKeys: [String] {
        [
            idToFirebaseConfigurationKeyImportant(),
            idToFirebaseConfigurationKey(),
            idToFirebaseConfigurationKeyFallback(),
            idToFirebaseConfigurationKeyIsEnabledFallback(),
            idToFirebaseConfigurationKeyIsEnabledFallbackAlternative(),
            idToFirebaseConfigurationKeyDefault()
        ]
    }

    fileprivate func idToFirebaseConfigurationKeyImportant() -> String { important + string }
    fileprivate func idToFirebaseConfigurationKeyDefault() -> String { string }

    /// blockchain_app_configuration_path_to_leaf_is_enabled
    fileprivate func idToFirebaseConfigurationKey() -> String {
        components.joined(separator: "_")
    }

    /// blockchain_app_configuration_path_to_leaf_is_enabled -> ios_ff_path_to_leaf_is_enabled
    fileprivate func idToFirebaseConfigurationKeyFallback() -> String {
        idToFirebaseConfigurationKey()
            .replacingOccurrences(
                of: "blockchain_app_configuration",
                with: "ios_ff"
            )
    }

    /// blockchain_app_configuration_path_to_leaf_is_enabled -> ios_ff_path_to_leaf
    fileprivate func idToFirebaseConfigurationKeyIsEnabledFallback() -> String {
        idToFirebaseConfigurationKey()
            .replacingOccurrences(
                of: "blockchain_app_configuration",
                with: "ios_ff"
            )
            .replacingOccurrences(
                of: "_is_enabled",
                with: ""
            )
    }

    /// blockchain_app_configuration_path_to_leaf_is_enabled -> ios_path_to_leaf
    fileprivate func idToFirebaseConfigurationKeyIsEnabledFallbackAlternative() -> String {
        idToFirebaseConfigurationKey()
            .replacingOccurrences(
                of: "blockchain_app_configuration",
                with: "ios"
            )
            .replacingOccurrences(
                of: "_is_enabled",
                with: ""
            )
    }
}

extension Dictionary {

    fileprivate subscript(firstOf first: Key, _ rest: Key...) -> Value? {
        self[firstOf: [first] + rest]
    }

    fileprivate subscript(firstOf keys: [Key]) -> Value? {
        for key in keys {
            guard let value = self[key] else { continue }
            return value
        }
        return nil
    }
}

extension Session.RemoteConfiguration {

    public struct Default: ExpressibleByDictionaryLiteral {
        let dictionary: [Tag.Reference: Any?]
        public init(dictionaryLiteral elements: (Tag.Event, Any?)...) {
            dictionary = Dictionary(uniqueKeysWithValues: elements.map { ($0.0.key(), $0.1) })
        }
    }
}

private actor ExponentialBackoff {

    var n = 0
    var rng = SystemRandomNumberGenerator()
    let unit: TimeInterval

    init(unit: TimeInterval = 0.5) {
        self.unit = unit
    }

    func next() async throws {
        n += 1
        try await Task.sleep(
            nanoseconds: UInt64(TimeInterval.random(
                in: unit...unit * pow(2, TimeInterval(n - 1)),
                using: &rng
            ) * 1_000_000)
        )
    }
}

extension Session.RemoteConfiguration {

    typealias Experiment = [String: [Int: AnyJSON]]

    public static func experiments(in app: AppProtocol) -> AnyPublisher<[String: Int], Never> {
        app.publisher(for: blockchain.ux.user.nabu.experiments, as: [String].self)
            .compactMap(\.value)
            .flatMap { [app] ids -> AnyPublisher<[String: Int], Never> in
                guard ids.isNotEmpty else { return .just([:]) }
                return ids.map { id in
                    app.publisher(for: blockchain.ux.user.nabu.experiment[id].group, as: Int.self)
                        .compactMap { result in result.value.map { (id, $0) } }
                }
                .combineLatest()
                .map(Dictionary.init(uniqueKeysWithValues:))
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    class Experiments {

        unowned let app: AppProtocol
        let session: URLSessionProtocol

        private var subscription: AnyCancellable?
        private var http: URLSessionDataTaskProtocol?
        private let baseURL = URL(string: "https://\(Bundle.main.plist?.RETAIL_CORE_URL ?? "api.blockchain.info/nabu-gateway")")!

        init(app: AppProtocol, session: URLSessionProtocol) {

            self.app = app
            self.session = session

            subscription = app.on(
                blockchain.session.event.did.sign.in,
                blockchain.session.event.did.sign.out
            ) { [unowned self] event in
                switch event.tag {
                case blockchain.session.event.did.sign.in:
                    try await request(token: app.stream(blockchain.user.token.nabu).compactMap(\.value).next())
                case blockchain.session.event.did.sign.out:
                    request(token: nil)
                default:
                    break
                }
            }
            .subscribe()

            request(token: nil)
        }

        deinit {
            subscription?.cancel()
            http?.cancel()
        }

        func request(token: String?) {
            var request = URLRequest(url: baseURL.appendingPathComponent("experiments"))
            do {
                request.allHTTPHeaderFields = try [
                    "Authorization": "Bearer " + token.or(throw: "No Authorization Token"),
                    "Accept-Language": "application/json"
                ]
            } catch {
                request.allHTTPHeaderFields = ["Accept-Language": "application/json"]
            }
            http = session.dataTask(with: request.peek("🌎", \.cURLCommand)) { [app] data, _, err in
                do {
                    let json = try JSONSerialization.jsonObject(
                        with: data.or(throw: err ?? "No data"),
                        options: []
                    ) as? [String: Int] ??^ "Expected [String: Int]"

                    app.state.transaction { state in
                        for (id, group) in json {
                            state.set(blockchain.ux.user.nabu.experiment[id].group, to: group)
                        }
                        state.set(blockchain.ux.user.nabu.experiments, to: Array(json.keys))
                    }
                } catch {
                    if app.state.doesNotContain(blockchain.ux.user.nabu.experiments) {
                        app.state.set(blockchain.ux.user.nabu.experiments, to: [String]())
                    }
                    app.post(error: error)
                }
            }
            http?.resume()
        }

        func decode(_ fetched: [String: Any?]) -> AnyPublisher<[String: Any?], Never> {
            Session.RemoteConfiguration.experiments(in: app)
                .map { [app] experiments in
                    fetched.deepMap { k, v in
                        do {
                            if let v = v as? [String: Any], let returns = v[Compute.CodingKey.returns] as? [String: Any] {
                                do {
                                    let experiment = try returns["experiment"].decode(Experiment.self)
                                    guard let (id, nabu) = experiment.firstAndOnly else {
                                        throw "Expected 1 experiment, got \(experiment.keys.count)"
                                    }
                                    return try (k, nabu[experiments[id] ??^ "No experiment for '\(id)'"] ??^ "No experiment config for '\(id)'")
                                } catch {
                                    if let defaultValue = v[Compute.CodingKey.default] {
                                        return (k, defaultValue)
                                    } else {
                                        throw error
                                    }
                                }
                            } else {
                                return (k, v)
                            }
                        } catch {
                            app.post(error: error)
                            return (k, v)
                        }
                    }
                }
                .eraseToAnyPublisher()
        }
    }
}
