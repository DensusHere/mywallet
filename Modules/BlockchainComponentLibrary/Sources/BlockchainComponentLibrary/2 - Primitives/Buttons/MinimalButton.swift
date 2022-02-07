// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

/// MinimalButton from the Figma Component Library.
///
///
/// # Usage:
///
/// `MinimalButton(title: "Tap me") { print("button did tap") }`
///
/// - Version: 1.0.1
///
/// # Figma
///
///  [Buttons](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=3%3A367)
public struct MinimalButton<LeadingView: View>: View {

    private let title: String
    private let isLoading: Bool
    private let foregroundColor: Color
    private let leadingView: LeadingView
    private let action: () -> Void

    @Environment(\.pillButtonSize) private var size
    @Environment(\.isEnabled) private var isEnabled

    private var colorCombination: PillButtonStyle.ColorCombination {
        .init(
            enabled: PillButtonStyle.ColorSet(
                foreground: foregroundColor,
                background: .semantic.background.opacity(0),
                border: Color(
                    light: .semantic.medium,
                    dark: .palette.dark300
                )
            ),
            pressed: PillButtonStyle.ColorSet(
                foreground: foregroundColor,
                background: .semantic.light,
                border: .semantic.primary
            ),
            disabled: PillButtonStyle.ColorSet(
                foreground: Color(
                    light: foregroundColor.opacity(0.7),
                    dark: .palette.grey600
                ),
                background: .semantic.background.opacity(0),
                border: Color(
                    light: .semantic.light,
                    dark: .palette.grey700
                )
            ),
            progressViewRail: .semantic.primary,
            progressViewTrack: Color(
                light: .semantic.blueBG,
                dark: .palette.white.opacity(0.25)
            )
        )
    }

    public init(
        title: String,
        isLoading: Bool = false,
        foregroundColor: Color = .semantic.primary,
        @ViewBuilder leadingView: () -> LeadingView,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.foregroundColor = foregroundColor
        self.leadingView = leadingView()
        self.action = action
    }

    public var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: Spacing.padding2) {
                leadingView
                    .frame(width: 24, height: 24)

                Text(title)
            }
        }
        .buttonStyle(
            PillButtonStyle(
                isLoading: isLoading,
                isEnabled: isEnabled,
                size: size,
                colorCombination: colorCombination
            )
        )
    }
}

extension MinimalButton where LeadingView == EmptyView {

    /// Create a minimal button without a leading view.
    /// - Parameters:
    ///   - title: Centered title label
    ///   - isLoading: True to display a loading indicator instead of the label.
    ///   - action: Action to be triggered on tap
    public init(
        title: String,
        isLoading: Bool = false,
        foregroundColor: Color = .semantic.primary,
        action: @escaping () -> Void
    ) {
        self.init(
            title: title,
            isLoading: isLoading,
            foregroundColor: foregroundColor,
            leadingView: { EmptyView() },
            action: action
        )
    }
}

struct MinimalButton_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            MinimalButton(title: "Enabled", action: {})
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Enabled")

            MinimalButton(
                title: "With Icon",
                leadingView: {
                    Icon.placeholder
                },
                action: {}
            )
            .previewLayout(.sizeThatFits)
            .previewDisplayName("With Icon")

            MinimalButton(title: "Disabled", action: {})
                .disabled(true)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Disabled")

            MinimalButton(title: "Loading", isLoading: true, action: {})
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Loading")

            MinimalButton(title: "Custom Text Color", foregroundColor: .semantic.error, action: {})
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Custom Color")
        }
        .padding()
    }
}
