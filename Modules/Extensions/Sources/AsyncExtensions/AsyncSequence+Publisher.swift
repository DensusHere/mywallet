// Copyright © Blockchain Luxembourg S.A. All rights reserved.

#if canImport(Combine)

import Combine
import Foundation

extension AsyncSequence {

    public func publisher() -> AsyncThrowingSequencePublisher<Self> {
        .init(self)
    }
}

// Once it is possible to express conformance to a non-throwing async sequence we should create a new type
// `AsyncSequencePublisher<S: nothrow AsyncSequence>`. At the moment the safest thing to do is capture the error and
// allow the consumer to ignore it if they wish
public struct AsyncThrowingSequencePublisher<S: AsyncSequence>: Combine.Publisher {

    public typealias Output = S.Element
    public typealias Failure = Error

    private var sequence: S

    public init(_ sequence: S) {
        self.sequence = sequence
    }

    public func receive<S>(
        subscriber: S
    ) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        subscriber.receive(
            subscription: Subscription(subscriber: subscriber, sequence: sequence)
        )
    }

    actor Subscription<
        Subscriber: Combine.Subscriber
    >: Combine.Subscription where Subscriber.Input == Output, Subscriber.Failure == Failure {

        private var sequence: S
        private var subscriber: Subscriber
        private var isCancelled = false

        private var demand: Subscribers.Demand = .none
        private var task: Task<Void, Error>?

        init(subscriber: Subscriber, sequence: S) {
            self.sequence = sequence
            self.subscriber = subscriber
        }

        nonisolated func request(_ demand: Subscribers.Demand) {
            Task { await _request(demand) }
        }

        private func _request(_ __demand: Subscribers.Demand) {
            demand = __demand
            guard demand > 0 else { return }
            task?.cancel()
            task = Task {
                var iterator = sequence.makeAsyncIterator()
                while !isCancelled, demand > 0 {
                    let element: S.Element?
                    do {
                        element = try await iterator.next()
                    } catch is CancellationError {
                        subscriber.receive(completion: .finished)
                        return
                    } catch {
                        subscriber.receive(completion: .failure(error))
                        throw CancellationError()
                    }
                    guard let element = element else {
                        subscriber.receive(completion: .finished)
                        throw CancellationError()
                    }
                    try Task.checkCancellation()
                    demand -= 1
                    demand += subscriber.receive(element)
                    await Task.yield()
                }
            }
        }

        nonisolated func cancel() {
            Task { await _cancel() }
        }

        private func _cancel() {
            task?.cancel()
            isCancelled = true
        }
    }
}

#endif
