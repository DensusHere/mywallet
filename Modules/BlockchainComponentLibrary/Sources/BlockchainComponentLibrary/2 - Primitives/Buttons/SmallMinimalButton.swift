// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

/// Syntactic suguar on MinimalButton to render it in a small size
///
/// # Usage
/// ```
/// SmallMinimalButton(title: "OK") { print("Tapped") }
/// ```
///
/// # Figma
///  [Buttons](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=6%3A2955)
public struct SmallMinimalButton: View {

    private let title: String
    private let isLoading: Bool
    private let action: () -> Void

    public init(
        title: String,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public init(
        title: String,
        isLoading: Bool = false,
        action: @escaping () async -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.action = { Task(priority: .userInitiated) { @MainActor in await action() } }
    }

    public var body: some View {
        MinimalButton(title: title, isLoading: isLoading, action: action)
            .pillButtonSize(.small)
    }
}

struct SmallMinimalButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SmallMinimalButton(title: "OK", isLoading: false) {
                print("Tapped")
            }
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Enabled")

            SmallMinimalButton(title: "OK", isLoading: false) {
                print("Tapped")
            }
            .disabled(true)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Disabled")

            SmallMinimalButton(title: "OK", isLoading: true) {
                print("Tapped")
            }
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Loading")
        }
    }
}
