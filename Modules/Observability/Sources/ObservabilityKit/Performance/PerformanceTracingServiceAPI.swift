// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Foundation
import ToolKit

/// The ID of the Trace
public struct TraceID: NewTypeString, RawRepresentable {

    public var value: String
    public var rawValue: String { value }

    public init(_ value: String) {
        self.value = value
    }

    public init?(rawValue: String) {
        value = rawValue
    }

    /// This trace should start when the PIN is enterered to the dashboard appearing
    public static let pinToDashboard: TraceID = "ios_trace_pin_to_dashboard"
}

/// This API provides a mechanism to trace metrics from the beginning to the end of a trace
public protocol PerformanceTracingServiceAPI {

    /// Start the trace
    /// - Parameter traceId: the unique ID to record this trace
    func begin(trace traceId: TraceID)

    /// End the trace
    /// - Parameter traceId: the unique ID to record this trace
    func end(trace traceId: TraceID)
}
