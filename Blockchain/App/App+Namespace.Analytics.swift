import AnalyticsKit
import BlockchainNamespace
import Combine
import FirebaseAnalytics
import ToolKit
import UIKit

final class AppAnalyticsTraitRepository: Session.Observer, TraitRepositoryAPI {

    struct Value: Decodable, Equatable {
        let value: Either<Tag.Reference, AnyJSON>
        let condition: Condition?
    }

    unowned let app: AppProtocol

    var _traits: [String: String] = [:]
    var _config: FetchResult.Value<[String: Value?]>?
    var traits: [String: String] { resolveTraits() }

    init(app: AppProtocol) {
        self.app = app
    }

    private var segment: AnyCancellable? {
        didSet { oldValue?.cancel() }
    }

    private var firebase: AnyCancellable? {
        didSet { oldValue?.cancel() }
    }

    func start() {

        segment = Session.RemoteConfiguration.experiments(in: app)
            .combineLatest(app.publisher(for: blockchain.ux.type.analytics.configuration.segment.user.traits, as: [String: Value?].self))
            .sink(to: My.fetched(experiments:additional:), on: self)

        firebase = app.publisher(for: blockchain.ux.type.analytics.configuration.firebase.user.traits, as: [String: Value?].self)
            .compactMap { $0.value?.compactMapValues(\.wrapped).filter { $1.condition.or(.yes).check() } }
            .flatMap { [app] config -> AnyPublisher<(String, String), Never> in
                config.map { name, property -> AnyPublisher<(String, String), Never> in
                    switch property.value {
                    case .left(let ref):
                        return app.publisher(for: ref, as: String.self)
                            .compactMap(\.value)
                            .map { (name, $0) }
                            .eraseToAnyPublisher()
                    case .right(let json):
                        return .just((name, String(describing: json.thing)))
                    }
                }
                .merge()
                .eraseToAnyPublisher()
            }
            .sink { name, trait in
                Analytics.setUserProperty(trait.prefix(36).string, forName: name)
            }
    }

    func stop() {
        segment = nil
        firebase = nil
    }

    private func fetched(experiments: [String: Int], additional: FetchResult.Value<[String: Value?]>) {
        _traits = experiments.mapValues(String.init)
        _config = additional
    }

    private func resolveTraits() -> [String: String] {
        var traits = _traits
        if let additional = _config?.value?.compactMapValues(\.wrapped) {
            for (key, result) in additional where result.condition.or(.yes).check() {
                switch result.value {
                case .left(let ref):
                    traits[key] = (
                        try? app.state.get(ref)
                    ) ?? (
                        try? app.remoteConfiguration.get(ref)
                    )
                case .right(let json):
                    traits[key] = String(describing: json.thing)
                }
            }
        }
        return traits
    }
}

final class AppAnalyticsObserver: Session.Observer {

    typealias Analytics = [Tag.Reference: Value]

    struct Value: Decodable {
        let name: String
        let context: [String: Either<Tag.Reference, AnyJSON>]?
        let condition: Condition?
    }

    unowned let app: AppProtocol
    let recorder: AnalyticsEventRecorderAPI

    init(
        app: AppProtocol,
        recorder: AnalyticsEventRecorderAPI = DIKit.resolve()
    ) {
        self.app = app
        self.recorder = recorder
    }

    private var segment: AnyCancellable? {
        didSet { oldValue?.cancel() }
    }

    private var firebase: AnyCancellable? {
        didSet { oldValue?.cancel() }
    }

    func start() {
        if segment != nil || firebase != nil {
            assertionFailure("Attempted to start what is already started 💣")
        }
        segment = app.publisher(for: blockchain.ux.type.analytics.configuration.segment.map, as: [String: Value].self)
            .compactMap(\.value)
            .map { [language = app.language] analytics -> Analytics in
                analytics.compactMapKeys { id in try? Tag.Reference(id: id, in: language) }
            }
            .combineLatest(Just(.nabu))
            .sink(to: My.observe, on: self)

        firebase = app.publisher(for: blockchain.ux.type.analytics.configuration.firebase.map, as: [String: Value].self)
            .compactMap(\.value)
            .map { [language = app.language] analytics -> Analytics in
                analytics.compactMapKeys { id in try? Tag.Reference(id: id, in: language) }
            }
            .combineLatest(Just(.firebase))
            .sink(to: My.observe, on: self)
    }

    func stop() {
        firebase = nil
        segment = nil
        bag.segment.removeAll()
        bag.firebase.removeAll()
    }

    private var bag = (segment: Set<AnyCancellable>(), firebase: Set<AnyCancellable>())

    func observe(_ events: Analytics, _ type: AnalyticsEventType) {
        switch type {
        case .firebase: bag.firebase.removeAll()
        case .nabu: bag.segment.removeAll()
        }
        for (event, value) in events {
            let subscription = app.on(event)
                .combineLatest(Just(value), Just(type))
                .sink(to: My.record, on: self)
            switch type {
            case .firebase: subscription.store(in: &bag.firebase)
            case .nabu: subscription.store(in: &bag.segment)
            }
        }
    }

    func record(_ event: Session.Event, _ value: Value, _ type: AnalyticsEventType) {
        guard value.condition.or(.yes).check() else { return }
        Task { @MainActor in
            do {
                try recorder.record(
                    event: AnyAnalyticsEvent(
                        type: type,
                        timestamp: event.date,
                        name: value.name,
                        params: value.context?.mapValues { either -> Any in
                            switch either {
                            case .left(let ref):
                                return try event.reference.context[ref]
                                    ?? event.context[ref]
                                    ?? app.state.get(ref)
                            case .right(let any):
                                return any.thing
                            }
                        }
                    )
                )
            } catch {
                app.post(error: error)
            }
        }
    }
}

struct Condition: Decodable, Equatable {
    let `if`: [Tag.Reference]?
    let unless: [Tag.Reference]?
}

extension Condition {

    static var yes: Condition { Condition(if: nil, unless: nil) }

    func check() -> Bool {
        (`if` ?? []).allSatisfy(isYes) && (unless ?? []).none(isYes)
    }
}

func isYes(_ ref: Tag.Reference) -> Bool {
    switch ref.tag {
    case blockchain.session.state.value:
        return app.state.result(for: ref).isYes
    case blockchain.session.configuration.value:
        return app.remoteConfiguration.result(for: ref).isYes
    default:
        return false
    }
}

struct AnyAnalyticsEvent: AnalyticsEvent {
    var type: AnalyticsEventType
    let timestamp: Date?
    let name: String
    let params: [String: Any]?
}
