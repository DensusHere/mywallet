// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

/// Syntactic suguar on SecondaryButton to render it in a small size
///
/// # Usage
/// ```
/// SmallSecondaryButton(title: "OK") { print("Tapped") }
/// ```
///
/// # Figma
///  [Buttons](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=6%3A2955)
public struct SmallSecondaryButton: View {

    private let title: String?
    private let icon: Icon?
    private let isLoading: Bool
    private let maxWidth: Bool
    private let action: () -> Void

    public init(
        title: String?,
        icon: Icon? = nil,
        isLoading: Bool = false,
        maxWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
        self.maxWidth = maxWidth
    }

    public var body: some View {
        SecondaryButton(
            title: title,
            isLoading: isLoading,
            leadingView: { icon },
            action: action
        )
        .pillButtonSize(maxWidth ? .smallHeightMaxWidth : .small)
    }
}

extension SmallSecondaryButton {
    public init(
        icon: Icon,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = nil
        self.icon = icon
        self.isLoading = isLoading
        self.maxWidth = false
        self.action = action
    }
}

struct SmallSecondaryButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SmallSecondaryButton(title: "OK", isLoading: false) {
                print("Tapped")
            }
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Enabled")

            SmallSecondaryButton(title: "OK", isLoading: false) {
                print("Tapped")
            }
            .disabled(true)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Disabled")

            SmallSecondaryButton(title: "OK", isLoading: true) {
                print("Tapped")
            }
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Loading")
        }
    }
}
