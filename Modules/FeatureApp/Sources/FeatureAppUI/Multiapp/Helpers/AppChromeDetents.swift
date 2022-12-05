// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Extensions
import SwiftUI
import UIKit

@available(iOS 15.0, *)
enum AppChromeDetents {
    case collapsed
    case semiCollapsed
    case expanded

    var identifier: UISheetPresentationController.Detent.Identifier {
        if #available(iOS 16, *) {
            switch self {
            case .collapsed:
                return .init("Custom:\(CollapsedDetent.self)")
            case .semiCollapsed:
                return .init("Custom:\(SemiCollapsedDetent.self)")
            case .expanded:
                return .init("Custom:\(ExpandedDetent.self)")
            }
        } else {
            switch self {
            case .collapsed:
                return .init("Custom:CollapsedDetent")
            case .semiCollapsed:
                return .init("Custom:SemiCollapsedDetent")
            case .expanded:
                return .init("Custom:ExpandedDetent")
            }
        }
    }

    var fraction: CGFloat {
        switch self {
        case .collapsed:
            return 0.9
        case .semiCollapsed:
            return 0.95
        case .expanded:
            if #available(iOS 16, *) {
                return 0.9999
            } else {
                return 0.985
            }
        }
    }

    @available(iOS 16, *)
    var detent: PresentationDetent {
        switch self {
        case .collapsed:
            return .collapsed
        case .semiCollapsed:
            return .semiCollapsed
        case .expanded:
            return .expanded
        }
    }

    static func detent(
        type: AppChromeDetents,
        context: @escaping (NSObjectProtocol) -> CGFloat
    ) -> UISheetPresentationController.Detent {
        .heightWithContext(id: type.identifier.rawValue, context: context)
    }

    static var supportedDetents: [AppChromeDetents] = [
        AppChromeDetents.collapsed,
        AppChromeDetents.semiCollapsed,
        AppChromeDetents.expanded
    ]
}

@available(iOS 16.0, *)
extension PresentationDetent {
    static let collapsed = Self.custom(CollapsedDetent.self)
    static let semiCollapsed = Self.custom(SemiCollapsedDetent.self)
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
struct SemiCollapsedDetent: FractionCustomPresentationDetent {
    static let fraction: CGFloat = 0.95

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
