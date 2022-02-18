// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

/// AlertCard from the Figma Component Library.
///
/// # Figma
///
/// [AlertCard](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=212%3A6021)
public struct AlertCard: View {

    private let title: String
    private let message: String
    private let variant: Variant
    private let isBordered: Bool
    private let onCloseTapped: (() -> Void)?

    /// Create an AlertCard view
    /// - Parameters:
    ///   - title: Text displayed in the card as a title
    ///   - message: Main text displayed on the card
    ///   - variant: Color variant. See `extension AlertCard.Variant` below for options.
    ///   - isBordered: Option to add a colored border to the card
    ///   - onCloseTapped: Closure executed when the user types the close icon. This value
    ///   is optional. If not provided you will not see a close button on the view.
    public init(
        title: String,
        message: String,
        variant: Variant = .default,
        isBordered: Bool = false,
        onCloseTapped: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.variant = variant
        self.isBordered = isBordered
        self.onCloseTapped = onCloseTapped
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .typography(.paragraph2)
                    .foregroundColor(variant.titleColor)
                Spacer()
                if let tap = onCloseTapped {
                    Button(
                        action: tap,
                        label: {
                            Icon.closev2.circle(
                                backgroundColor: Color(
                                    light: .semantic.medium,
                                    dark: .palette.grey800
                                )
                            )
                            .accentColor(.palette.grey400)
                            .frame(width: 24)
                        }
                    )
                }
            }
            Text(message)
                .typography(.caption1)
                .foregroundColor(.semantic.title)
        }
        .padding(Spacing.padding2)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.semantic.light)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(variant.borderColor, lineWidth: isBordered ? 1 : 0)
        )
    }

    /// Style variant for AlertCard
    public struct Variant {
        fileprivate let titleColor: Color
        fileprivate let borderColor: Color
    }
}

extension AlertCard.Variant {
    public static let `default` = AlertCard.Variant(
        titleColor: .semantic.title,
        borderColor: Color(
            light: .palette.grey300,
            dark: .palette.dark600
        )
    )

    // success
    public static let success = AlertCard.Variant(
        titleColor: .semantic.success,
        borderColor: .semantic.success
    )

    // warning
    public static let warning = AlertCard.Variant(
        titleColor: .semantic.warning,
        borderColor: .semantic.warning
    )

    // error
    public static let error = AlertCard.Variant(
        titleColor: .semantic.error,
        borderColor: .semantic.error
    )
}

struct AlertCard_Previews: PreviewProvider {

    private static var message: String {
        "Card alert copy that directs the user to take an action or let’s them know what happened."
    }

    static var previews: some View {
        Group {
            preview(title: "Default", variant: .default)

            preview(title: "Success", variant: .success)

            preview(title: "Warning", variant: .warning)

            preview(title: "Error", variant: .error)
        }
        .padding()
    }

    @ViewBuilder private static func preview(title: String, variant: AlertCard.Variant) -> some View {
        VStack {
            AlertCard(
                title: title,
                message: message,
                variant: variant,
                onCloseTapped: {}
            )
            AlertCard(
                title: title,
                message: message,
                variant: variant,
                onCloseTapped: {}
            )
            .colorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName(title)

        VStack {
            AlertCard(
                title: "\(title) Bordered",
                message: message,
                variant: variant,
                isBordered: true,
                onCloseTapped: {}
            )
            AlertCard(
                title: "\(title) Bordered",
                message: message,
                variant: variant,
                isBordered: true,
                onCloseTapped: {}
            )
            .colorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("\(title) Bordered")
    }
}
