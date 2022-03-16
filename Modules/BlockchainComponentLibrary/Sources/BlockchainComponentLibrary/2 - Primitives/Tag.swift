// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

/// Contained text used for informational data such as dates or warnings.
///
/// # Figma
///
/// [TagView](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=212%3A5974)
public struct TagView: View {

    private let text: String
    private let variant: Variant
    private let size: Size

    /// Create a tag view
    /// - Parameters:
    ///   - text: Text displayed in the tag
    ///   - variant: Color variant. See `extension TagView.Variant` below for options.
    public init(text: String, variant: Variant = .default, size: Size = .small) {
        self.text = text
        self.variant = variant
        self.size = size
    }

    public var body: some View {
        Text(text)
            .typography(size.typography)
            .foregroundColor(variant.textColor)
            .padding(size.padding)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(variant.backgroundColor)
            )
    }

    /// Style variant for TagView
    public struct Variant {
        fileprivate let backgroundColor: Color
        fileprivate let textColor: Color
    }

    /// Size variant for TagView
    public struct Size {
        fileprivate let typography: Typography
        fileprivate let padding: EdgeInsets
    }
}

extension TagView.Size {

    /// .caption2, padding 8x4
    public static let small = Self(
        typography: .caption2,
        padding: EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
    )

    /// .paragraph2, padding 12x6
    public static let large = Self(
        typography: .paragraph2,
        padding: EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
    )
}

extension TagView.Variant {

    /// default
    public static let `default` = TagView.Variant(
        backgroundColor: .init(light: .semantic.light, dark: .palette.dark600),
        textColor: .init(light: .semantic.title, dark: .semantic.title)
    )

    /// infoalt
    public static let infoAlt = TagView.Variant(
        backgroundColor: .init(light: .palette.blue000, dark: .palette.dark600),
        textColor: .init(light: .semantic.primary, dark: .semantic.primary)
    )

    /// success
    public static let success = TagView.Variant(
        backgroundColor: .init(light: .palette.green100, dark: .semantic.success),
        textColor: .init(light: .semantic.success, dark: .palette.dark900)
    )

    /// warning
    public static let warning = TagView.Variant(
        backgroundColor: .init(light: .palette.orange100, dark: .semantic.warning),
        textColor: .init(light: .palette.orange600, dark: .palette.dark900)
    )

    /// error
    public static let error = TagView.Variant(
        backgroundColor: .init(light: .palette.red100, dark: .semantic.error),
        textColor: .init(light: .semantic.error, dark: .palette.dark900)
    )
}

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TagView(text: "Informational")

            TagView(text: "Informational")
                .colorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Default")

        VStack {
            TagView(text: "Informational", size: .large)

            TagView(text: "Informational", size: .large)
                .colorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Default Large")

        VStack {
            TagView(text: "Info Alt", variant: .infoAlt)

            TagView(text: "Info Alt", variant: .infoAlt)
                .colorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("InfoAlt")

        VStack {
            TagView(text: "Info Alt", variant: .infoAlt, size: .large)

            TagView(text: "Info Alt", variant: .infoAlt, size: .large)
                .colorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("InfoAlt Large")

        VStack {
            TagView(text: "Success", variant: .success)

            TagView(text: "Success", variant: .success)
                .colorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Success")

        VStack {
            TagView(text: "Success", variant: .success, size: .large)

            TagView(text: "Success", variant: .success, size: .large)
                .colorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Success Large")

        VStack {
            TagView(text: "Warning", variant: .warning)

            TagView(text: "Warning", variant: .warning)
                .colorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Warning")

        VStack {
            TagView(text: "Warning", variant: .warning, size: .large)

            TagView(text: "Warning", variant: .warning, size: .large)
                .colorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Warning Large")

        VStack {
            TagView(text: "Error", variant: .error)

            TagView(text: "Error", variant: .error)
                .colorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Error")

        VStack {
            TagView(text: "Error", variant: .error, size: .large)

            TagView(text: "Error", variant: .error, size: .large)
                .colorScheme(.dark)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Error Large")
    }
}
