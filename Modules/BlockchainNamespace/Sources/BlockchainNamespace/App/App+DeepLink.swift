// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation

extension App {

    public class DeepLink {

        private(set) unowned var app: AppProtocol
        private var bag: Set<AnyCancellable> = []

        init(_ app: AppProtocol) {
            self.app = app
        }

        func start() {
            let rules = app
                .publisher(for: blockchain.app.configuration.deep_link.rules, as: [Rule].self)
                .compactMap(\.value)
                .removeDuplicates()

            app.on(blockchain.app.process.deep_link)
                .combineLatest(
                    app.publisher(for: blockchain.app.is.ready.for.deep_link, as: Bool.self)
                        .compactMap(\.value)
                        .removeDuplicates()
                )
                .filter(\.1)
                .map(\.0)
                .combineLatest(rules)
                .sink { [weak self] event, rules in
                    self?.process(event: event, with: rules)
                }
                .store(in: &bag)
        }

        func process(event: Session.Event, with rules: [Rule]) {
            do {
                try process(
                    url: event.context.decode(blockchain.app.process.deep_link.url, as: URL.self),
                    with: rules
                )
            } catch {
                app.post(error: error)
            }
        }

        func process(url: URL, with rules: [Rule]) {
            do {
                guard let match = rules.match(for: url) else {
                    throw ParsingError.nomatch
                }

                app.post(event: match.rule.event, context: match.parameters())
            } catch {
                #if DEBUG
                do {
                    let dsl = try DSL(url, app: app)
                    app.state.transaction { state in
                        for (tag, value) in dsl.context {
                            state.set(tag, to: value)
                        }
                    }
                    if let event = dsl.event {
                        app.post(event: event, context: dsl.context)
                    }
                } catch {
                    app.post(error: error)
                }
                #else
                app.post(error: error)
                #endif
            }
        }
    }
}

extension App.DeepLink {
    enum ParsingError: Error {
        case nomatch
    }
}

extension App.DeepLink {

    struct DSL: Equatable, Codable {
        var event: Tag.Reference?
        var context: [Tag: String] = [:]
    }
}

extension App.DeepLink.DSL {

    struct Error: Swift.Error {
        let message: String
    }

    static func isDSL(_ url: URL) -> Bool {
        url.path == "/app"
    }

    init(_ url: URL, app: AppProtocol) throws {
        guard App.DeepLink.DSL.isDSL(url) else {
            throw Error(message: "Not a \(Self.self): \(url)")
        }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw Error(message: "Failed to initialise a \(Self.self) from url \(url)")
        }
        event = try components.fragment.map { try Tag.Reference(id: $0, in: app.language) }
        var context: [Tag: String] = [:]
        for item in components.queryItems ?? [] {
            try context[Tag(id: item.name, in: app.language)] = item.value
        }
        self.context = context
    }
}

extension App.DeepLink {
    public struct Rule: Codable, Equatable {
        public init(pattern: String, event: Tag.Reference, parameters: [App.DeepLink.Rule.Parameter]) {
            self.pattern = pattern
            self.event = event
            self.parameters = parameters
        }

        public let pattern: String
        public let event: Tag.Reference
        public let parameters: [Parameter]
    }
}

extension App.DeepLink.Rule {

    public struct Parameter: Codable, Equatable {
        public init(name: String, alias: Tag) {
            self.name = name
            self.alias = alias
        }

        public let name: String
        public let alias: Tag
    }

    public struct Match {
        public let url: URL
        public let rule: App.DeepLink.Rule
        public let result: NSTextCheckingResult
    }
}

extension App.DeepLink.Rule.Match {
    public func parameters() -> [Tag: String] {

        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems ?? []

        return rule.parameters
            .reduce(into: [:]) { rules, parameter in
                let range = result.range(withName: parameter.name)
                rules[parameter.alias] = range.location == NSNotFound
                    ? items[named: parameter.name]?.value
                    : NSString(string: url.absoluteString).substring(with: range)
            }
    }
}

extension Collection where Element == App.DeepLink.Rule {

    public func match(for url: URL) -> App.DeepLink.Rule.Match? {
        lazy.compactMap { rule -> App.DeepLink.Rule.Match? in
            guard let pattern = try? NSRegularExpression(pattern: rule.pattern) else {
                return nil
            }
            let string = url.absoluteString
            guard let match = pattern.firstMatch(
                in: string,
                range: NSRange(string.startIndex..., in: string)
            ) else {
                return nil
            }
            return App.DeepLink.Rule.Match(
                url: url,
                rule: rule,
                result: match
            )
        }
        .first
    }
}

extension Collection where Element == URLQueryItem {

    public subscript(named name: String) -> URLQueryItem? {
        item(named: name)
    }

    public func item(named name: String) -> URLQueryItem? {
        first(where: { $0.name == name })
    }
}
