// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation

extension Publisher where Failure: TimeoutFailure {

    /// Attempts to recreate a failed subscription with the upstream publisher up to the number of times you specify with
    /// each retry delayed by constant time `delay`
    public func retry<S: Scheduler>(
        max: Int = Int.max,
        delay interval: DispatchTimeInterval,
        if condition: @escaping (Failure) -> Bool = { _ in true },
        scheduler: S,
        timeout: Failure = Failure.timeout
    ) -> Publishers.RetryDelay<Self, S> {
        retry(max: max, delay: .init(interval), if: condition, scheduler: scheduler, timeout: timeout)
    }

    /// Attempts to recreate a failed subscription with the upstream publisher up to the number of times you specify with
    /// each retry delayed by ƒ(x) defined by `delay` IntervalDuration
    public func retry<S: Scheduler>(
        max: Int = Int.max,
        delay: IntervalDuration,
        if condition: @escaping (Failure) -> Bool = { _ in true },
        scheduler: S,
        timeout: Failure = Failure.timeout
    ) -> Publishers.RetryDelay<Self, S> {
        .init(upstream: self, max: max, delay: delay, condition: condition, scheduler: scheduler, timeout: timeout)
    }
}

extension Publisher where Failure == Error {

    /// Attempts to recreate a failed subscription with the upstream publisher up to the number of times you specify with
    /// each retry delayed by constant time `delay`
    public func retry<S: Scheduler>(
        max: Int = Int.max,
        delay interval: DispatchTimeInterval,
        if condition: @escaping (Failure) -> Bool = { _ in true },
        scheduler: S,
        timeout: Failure = PublisherTimeoutError.timeout
    ) -> Publishers.RetryDelay<Self, S> {
        retry(max: max, delay: .init(interval), if: condition, scheduler: scheduler, timeout: timeout)
    }

    /// Attempts to recreate a failed subscription with the upstream publisher up to the number of times you specify with
    /// each retry delayed by ƒ(x) defined by `delay` IntervalDuration
    public func retry<S: Scheduler>(
        max: Int = Int.max,
        delay: IntervalDuration,
        if condition: @escaping (Failure) -> Bool = { _ in true },
        scheduler: S,
        timeout: Failure = PublisherTimeoutError.timeout
    ) -> Publishers.RetryDelay<Self, S> {
        .init(upstream: self, max: max, delay: delay, condition: condition, scheduler: scheduler, timeout: timeout)
    }
}

extension Publisher {

    /// Attempts to recreate a failed subscription with the upstream publisher up to the number of times you specify with
    /// each retry delayed by constant time `delay`
    public func retry<S: Scheduler>(
        max: Int = Int.max,
        delay interval: DispatchTimeInterval,
        if condition: @escaping (Failure) -> Bool = { _ in true },
        scheduler: S,
        timeout: Failure
    ) -> Publishers.RetryDelay<Self, S> {
        retry(max: max, delay: .init(interval), if: condition, scheduler: scheduler, timeout: timeout)
    }

    /// Attempts to recreate a failed subscription with the upstream publisher up to the number of times you specify with
    /// each retry delayed by ƒ(x) defined by `delay` IntervalDuration
    public func retry<S: Scheduler>(
        max: Int = Int.max,
        delay: IntervalDuration,
        if condition: @escaping (Failure) -> Bool = { _ in true },
        scheduler: S,
        timeout: Failure
    ) -> Publishers.RetryDelay<Self, S> {
        .init(upstream: self, max: max, delay: delay, condition: condition, scheduler: scheduler, timeout: timeout)
    }
}

public protocol TimeoutFailure: Error {
    static var timeout: Self { get }
}

public enum PublisherTimeoutError: TimeoutFailure {
    case timeout
}

extension Publisher where Failure: TimeoutFailure {

    /// Keep re-subscribing to the upstream publisher until the `until` condition is met.
    public func poll(
        max attempts: Int = Int.max,
        until: @escaping (Output) -> Bool = { _ in false },
        delay: DispatchTimeInterval = .seconds(30)
    ) -> AnyPublisher<Output, Failure> {
        poll(max: attempts, until: until, delay: .constant(delay), scheduler: DispatchQueue.main)
    }

    /// Keep re-subscribing to the upstream publisher until the `until` condition is met.
    public func poll(
        max attempts: Int = Int.max,
        until: @escaping (Output) -> Bool = { _ in false },
        delay: DispatchTimeInterval = .seconds(30),
        scheduler: some Scheduler
    ) -> AnyPublisher<Output, Failure> {
        poll(max: attempts, until: until, delay: .constant(delay), scheduler: scheduler)
    }

    /// Keep re-subscribing to the upstream publisher until the `until` condition is met.
    public func poll(
        max attempts: Int = Int.max,
        until: @escaping (Output) -> Bool = { _ in false },
        delay: IntervalDuration,
        scheduler: some Scheduler
    ) -> AnyPublisher<Output, Failure> {
        flatMap { output -> AnyPublisher<Output, Failure> in
            guard until(output) else {
                return Fail(error: Failure.timeout).eraseToAnyPublisher()
            }
            return Just(output).setFailureType(to: Failure.self).eraseToAnyPublisher()
        }
        .retry(max: attempts, delay: delay, scheduler: scheduler, timeout: Failure.timeout)
        .eraseToAnyPublisher()
    }
}

extension Publisher {

    /// Keep re-subscribing to the upstream publisher until the `until` condition is met.
    public func poll(
        max attempts: Int = Int.max,
        until: @escaping (Output) -> Bool = { _ in false },
        delay: DispatchTimeInterval = .seconds(30)
    ) -> AnyPublisher<Output, Error> {
        poll(max: attempts, until: until, delay: .constant(delay), scheduler: DispatchQueue.main)
    }

    /// Keep re-subscribing to the upstream publisher until the `until` condition is met.
    public func poll(
        max attempts: Int = Int.max,
        until: @escaping (Output) -> Bool = { _ in false },
        delay: DispatchTimeInterval = .seconds(30),
        scheduler: some Scheduler
    ) -> AnyPublisher<Output, Error> {
        poll(max: attempts, until: until, delay: .constant(delay), scheduler: scheduler)
    }

    /// Keep re-subscribing to the upstream publisher until the `until` condition is met.
    public func poll(
        max attempts: Int = Int.max,
        until: @escaping (Output) -> Bool = { _ in false },
        delay: IntervalDuration,
        scheduler: some Scheduler
    ) -> AnyPublisher<Output, Error> {
        mapError { $0 as Error }
            .flatMap { output -> AnyPublisher<Output, Error> in
                guard until(output) else { return Fail(error: PublisherTimeoutError.timeout).eraseToAnyPublisher() }
                return Just(output).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .retry(max: attempts, delay: delay, scheduler: scheduler, timeout: PublisherTimeoutError.timeout)
            .eraseToAnyPublisher()
    }
}

extension Publishers {

    public struct RetryDelay<Upstream: Publisher, S: Scheduler>: Publisher {

        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure

        public let upstream: Upstream

        public let retries: Int
        public let max: Int
        public let delay: IntervalDuration
        public let scheduler: S
        public let condition: (Failure) -> Bool
        public let timeout: Failure

        public init(
            upstream: Upstream,
            retries: Int = 0,
            max: Int,
            delay: IntervalDuration,
            condition: @escaping (Failure) -> Bool,
            scheduler: S,
            timeout: Failure
        ) {
            self.upstream = upstream
            self.retries = retries
            self.max = max
            self.delay = delay
            self.scheduler = scheduler
            self.condition = condition
            self.timeout = timeout
        }

        public func receive<S: Subscriber>(
            subscriber: S
        ) where Upstream.Failure == S.Failure, Upstream.Output == S.Input {
            upstream.catch { e -> AnyPublisher<Output, Failure> in
                guard retries < max else { return Fail(error: timeout).eraseToAnyPublisher() }
                guard condition(e) else { return Fail(error: e).eraseToAnyPublisher() }
                return Fail(error: e)
                    .delay(for: .seconds(delay(retries + 1)), scheduler: scheduler)
                    .catch { _ in
                        RetryDelay(
                            upstream: upstream,
                            retries: retries + 1,
                            max: max,
                            delay: delay,
                            condition: condition,
                            scheduler: scheduler,
                            timeout: timeout
                        )
                    }
                    .eraseToAnyPublisher()
            }
            .subscribe(subscriber)
        }
    }
}
