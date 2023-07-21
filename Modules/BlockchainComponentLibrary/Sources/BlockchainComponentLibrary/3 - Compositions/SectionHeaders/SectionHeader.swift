// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI

/// SectionHeader from the Figma Component Library.
///
/// # Usage:
///
/// Can be a Section Header inside a List, VStack or other.
/// ```
/// List {
///     Section(header: SectionHeader(title: "Wallets & Accounts"))  {
///         ...
///     }
/// }
/// ```
///
/// - Version: 1.0.1
///
/// # Figma
///
///  [Section Header](https://www.figma.com/file/nlSbdUyIxB64qgypxJkm74/03---iOS-%7C-Shared?node-id=209%3A11327)
public struct SectionHeader<Trailing: View, Decoration: View>: View {

    private let title: String
    private let decoration: Decoration
    private let variant: SectionHeaderVariant
    private let trailing: Trailing

    /// Initialize a section header with a trailing view
    /// - Parameters:
    ///   - title: Leading title text
    ///   - variant: `.regular` (default) for wallet, `.large` for exchange.
    ///   - trailing: Generic view displayed trailing in the section header. (for exchange)
    public init(
        title: String,
        variant: SectionHeaderVariant = .regular,
        @ViewBuilder decoration: @escaping() -> Decoration = { EmptyView() },
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.variant = variant
        self.decoration = decoration()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack {
            Text(title)
                .typography(variant.typography)
                .foregroundColor(variant.fontColor)
            decoration
                .frame(maxHeight: 24)
            Spacer()
            trailing
                .frame(maxHeight: 24)
        }
        .padding(variant.padding)
        .background(variant.backgroundColor)
        .listRowInsets(
            EdgeInsets(
                top: 0,
                leading: 0,
                bottom: 0,
                trailing: 0
            )
        )
    }
}

/// Variant types for `SectionHeader`
public struct SectionHeaderVariant {
    let typography: Typography
    let fontColor: Color
    let backgroundColor: Color
    let padding: EdgeInsets

    /// Regular section header variant, used for Wallet app.
    public static let regular = Self(
        typography: .caption2,
        fontColor: .semantic.title,
        backgroundColor: .semantic.light,
        padding: EdgeInsets(
            top: Spacing.baseline,
            leading: Spacing.padding3,
            bottom: Spacing.baseline,
            trailing: Spacing.padding3
        )
    )

    /// Large section header variant, used for exchange app.
    public static let large = Self(
        typography: .paragraph2,
        fontColor: Color(
            light: .palette.grey600,
            dark: .palette.dark200
        ),
        backgroundColor: .semantic.background,
        padding: EdgeInsets(
            top: 14,
            leading: 16,
            bottom: 14,
            trailing: 12
        )
    )

    public static let superapp = Self(
        typography: .body2,
        fontColor: .semantic.body,
        backgroundColor: .semantic.light,
        padding: EdgeInsets(
            top: Spacing.padding1,
            leading: 0,
            bottom: Spacing.padding1,
            trailing: 0
        )
    )

    public static let superappLight = Self(
        typography: .body2,
        fontColor: .semantic.text,
        backgroundColor: .semantic.light,
        padding: EdgeInsets(
            top: Spacing.padding1,
            leading: 0,
            bottom: Spacing.padding1,
            trailing: Spacing.padding2
        )
    )
}

struct SectionHeader_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            SectionHeader(
                title: "Regular",
                decoration: { IconButton(icon: .questionFilled) {} },
                trailing: { IconButton(icon: .qrCode) {} }
            )
            .previewDisplayName("Regular")

            SectionHeader(
                title: "Large",
                variant: .large,
                decoration: { IconButton(icon: .questionFilled) {} },
                trailing: { IconButton(icon: .qrCode) {} }
            )
            .previewDisplayName("Large")

            SectionHeader(
                title: "Superapp",
                variant: .superapp,
                decoration: { IconButton(icon: .questionFilled) {} },
                trailing: { IconButton(icon: .qrCode) {} }
            )
            .previewDisplayName("Superapp")

            SectionHeader(
                title: "Large with Trailing",
                variant: .large,
                decoration: { IconButton(icon: .questionFilled) {} },
                trailing: { IconButton(icon: .qrCode) {} }
            )
            .previewDisplayName("Large with Trailing")
        }
        .previewLayout(.sizeThatFits)
        .frame(width: 375)
    }
}
