// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension PresentationDetent {
    static let collapsed = Self.custom(CollapsedDetent.self)
    static let expanded = Self.custom(ExpandedDetent.self)
}

@available(iOS 16.0, *)
protocol FractionCustomPresentationDetent: CustomPresentationDetent {
    static var fraction: CGFloat { get }
}

@available(iOS 16.0, *)
struct CollapsedDetent: FractionCustomPresentationDetent {
    static let fraction: CGFloat = 0.9

    static func height(in context: Context) -> CGFloat? {
        // this fixed fraction is really not that great
        // quite tricky to pass in an updated fraction based on the header height...
        context.maxDetentValue * fraction
    }
}

@available(iOS 16.0, *)
struct ExpandedDetent: FractionCustomPresentationDetent {
    static let fraction: CGFloat = 0.9999
    static func height(in context: Context) -> CGFloat? {
        context.maxDetentValue * fraction
    }
}
