import BlockchainComponentLibrary
import BlockchainNamespace
import Localization
import SwiftUI

public struct ErrorView<Fallback: View>: View {

    typealias L10n = LocalizationConstants.UX.Error

    @BlockchainApp var app

    public let ux: UX.Error
    public let fallback: () -> Fallback
    public let dismiss: () -> Void

    public init(
        ux: UX.Error,
        @ViewBuilder fallback: @escaping () -> Fallback,
        dismiss: @escaping () -> Void
    ) {
        self.ux = ux
        self.fallback = fallback
        self.dismiss = dismiss
    }

    let overlay = 7.5

    public var body: some View {
        VStack {
            VStack(spacing: .none) {
                Spacer()
                icon
                content
                Spacer()
                metadata
            }
            .multilineTextAlignment(.center)
            actions
        }
        .padding()
        .onAppear {
            app.post(value: ux, of: blockchain.ux.error)
        }
        .apply { view in
            #if os(iOS)
            view.navigationBarBackButtonHidden(true)
                .navigationBarItems(
                    leading: EmptyView(),
                    trailing: IconButton(
                        icon: Icon.closeCirclev2,
                        action: dismiss
                    )
                )
            #endif
        }
        .background(Color.semantic.background)
    }

    @ViewBuilder
    private var icon: some View {
        Group {
            if let icon = ux.icon {
                AsyncMedia(
                    url: icon.url,
                    placeholder: {
                        Image(systemName: "squareshape.squareshape.dashed")
                            .resizable()
                            .overlay(ProgressView().opacity(0.3))
                            .foregroundColor(.semantic.light)
                    }
                )
                .accessibilityLabel(icon.accessibility?.description ?? L10n.icon.accessibility)
            } else {
                fallback()
            }
        }
        .scaledToFit()
        .frame(maxHeight: 100.pt)
        .padding(floor(overlay / 2).i.vmin)
        .overlay(
            Group {
                ZStack {
                    Circle()
                        .foregroundColor(.semantic.background)
                        .scaleEffect(1.3)
                    if let status = ux.icon?.status?.url {
                        AsyncMedia(
                            url: status,
                            content: { image in image.scaleEffect(0.9) },
                            placeholder: {
                                ProgressView().progressViewStyle(.circular)
                            }
                        )
                    } else {
                        Icon.alert
                            .scaledToFit()
                            .accentColor(.semantic.warning)
                    }
                }
                .frame(
                    width: overlay.vmin,
                    height: overlay.vmin
                )
                .offset(x: -overlay, y: overlay)
            },
            alignment: .topTrailing
        )
    }

    @ViewBuilder
    private var content: some View {
        Text(rich: ux.title)
            .typography(.title3)
            .foregroundColor(.semantic.title)
            .padding(.bottom, Spacing.padding1.pt)
        Text(rich: ux.message)
            .typography(.body1)
            .foregroundColor(.semantic.body)
            .padding(.bottom, Spacing.padding2.pt)
        if let action = ux.actions.dropFirst(2).first {
            SmallMinimalButton(
                title: action.title,
                action: { post(action) }
            )
        }
    }

    private var columns: [GridItem] = [
        GridItem(.flexible(minimum: 32, maximum: 48), spacing: 16),
        GridItem(.flexible(minimum: 100, maximum: .infinity), spacing: 16)
    ]

    @ViewBuilder
    private var metadata: some View {
        if !ux.metadata.isEmpty {
            HStack {
                LazyVGrid(columns: columns, alignment: .leading) {
                    ForEach(Array(ux.metadata), id: \.key) { key, value in
                        Text(rich: key)
                        Text(rich: value)
                    }
                }
                .frame(maxWidth: .infinity)
                Icon.copy.frame(width: 16.pt, height: 16.pt)
                    .accentColor(.semantic.light)
            }
            .typography(.micro)
            .foregroundColor(.semantic.body)
            .padding(8.pt)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.semantic.light, lineWidth: 1)
                    .background(Color.semantic.background)
            )
            .contextMenu {
                Button(
                    action: {
                        let string = String(ux.metadata.map { "\($0): \($1)" }.joined(by: "\n"))
                        #if canImport(UIKit)
                        UIPasteboard.general.string = string
                        #else
                        NSPasteboard.general.setString(string, forType: .string)
                        #endif
                    },
                    label: {
                        Label(L10n.copy, systemImage: "doc.on.doc.fill")
                    }
                )
            }
            .padding(.bottom)
        }
    }

    @ViewBuilder
    private var actions: some View {
        ForEach(ux.actions.prefix(2).indexed(), id: \.element) { index, action in
            if index == ux.actions.startIndex {
                PrimaryButton(
                    title: action.title,
                    action: { post(action) }
                )
            } else {
                MinimalButton(
                    title: action.title,
                    action: { post(action) }
                )
            }
        }
    }

    private func post(_ action: UX.Action) {
        switch action.url {
        case let url?:
            app.post(value: url, of: blockchain.ux.error.then.launch.url)
        case nil:
            dismiss()
        }
    }
}

extension ErrorView where Fallback == AnyView {

    public init(
        ux: UX.Error,
        dismiss: @escaping () -> Void
    ) {
        self.ux = ux
        fallback = {
            AnyView(
                Icon.error.foregroundColor(.semantic.warning)
            )
        }
        self.dismiss = dismiss
    }
}

// swiftlint:disable type_name
// swiftlint:disable line_length
struct ErrorView_Preview: PreviewProvider {

    static var previews: some View {
        PrimaryNavigationView {
            ErrorView(
                ux: .init(
                    title: "Error Title",
                    message: "Here’s some explainer text that helps the user understand the problem, with a [potential link](http://blockchain.com) for the user to tap to learn more.",
                    icon: UX.Icon(
                        url: "https://bitcoin.org/img/icons/opengraph.png",
                        accessibility: nil
                    ),
                    metadata: [
                        "ID": "bab80077-f1fb-424f-b52b-dbb935d0f7bf",
                        "Request": "825ea2c0-9f5f-4e2a-be8f-0e3572f0bec2"
                    ],
                    actions: [
                        .init(
                            title: "Primary",
                            url: "http://blockchain.com/app/asset/BTC/buy/change_payment_method"
                        ),
                        .init(title: "Secondary"),
                        .init(title: "Small Primary")
                    ]
                ),
                dismiss: {}
            )
            .previewDevice("iPhone SE (2nd generation)")
            .previewDisplayName("iPhone SE (2nd generation)")
            .app(App.preview)
        }
    }
}
