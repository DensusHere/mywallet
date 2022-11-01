// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

#if canImport(UIKit)

extension View {

    /// Finds a scroll view from SwiftUI, this looks for a view host and finds the first UIScrollview.
    /// - Parameter customize: A closure that provides the UIScrollView
    public func findScrollView(customize: @escaping (UIScrollView) -> Void) -> some View {
        inject(UIKitIntrospection(
            selector: { introspectionView in
                guard let viewHost = Introspect.findViewHost(introspectionView) else {
                    return nil
                }
                return Introspect.previousSibling(containing: UIScrollView.self, from: viewHost)
            },
            customize: customize
        ))
    }

    public func introspectTabBarController(customize: @escaping (UITabBarController) -> Void) -> some View {
        inject(UIKitIntrospectionViewController(
            selector: { introspectionViewController in

                if let navigationController = introspectionViewController.tabBarController {
                    return navigationController
                }

                return Introspect.previousSibling(ofType: UITabBarController.self, from: introspectionViewController)
            },
            customize: customize
        ))
    }
}

#endif
