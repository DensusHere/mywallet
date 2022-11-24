// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import _Concurrency
import Blockchain
import BlockchainUI
import FeatureStakingDomain
import SwiftUI

typealias L10n = LocalizationConstants.Staking

@MainActor
public struct StakingConsiderationsView: View {

    let story = blockchain.ux.transaction.disclaimer

    @BlockchainApp var app
    @Environment(\.context) var context

    var pages: [Page]

    @State private var current: Tag.Reference

    public init() {
        self.init(pages: stakingConsiderations)!
    }

    public init?(pages: [Page]) {
        self.pages = pages
        guard let first = pages.first else { return nil }
        _current = .init(wrappedValue: first.id)
    }

    public var body: some View {
        PrimaryNavigationView {
            #if os(iOS)
            TabView(selection: $current) {
                content
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            TabView(selection: $current) {
                content
            }
            #endif
        }
        .primaryNavigation(
            trailing: {
                IconButton(icon: .closeCirclev2) {
                    app.post(event: story.article.plain.navigation.bar.button.close.tap[].ref(to: context), context: context)
                }
            }
        )
        .onAppear {
            app.post(event: story[].ref(to: context), context: context)
            app.post(event: story.article.plain.lifecycle.event.did.enter[].ref(to: context), context: context)
        }
        .onDisappear {
            app.post(event: story.article.plain.lifecycle.event.did.exit[].ref(to: context), context: context)
        }
    }

    @ViewBuilder var content: some View {
        let nexts: [Page?] = pages.dropFirst().array + [nil]
        ForEach(Array(zip(pages, nexts)), id: \.0.id) { page, next in
            VStack {
                Spacer()
                    .frame(height: 105.pt)
                ZStack { page }
                Spacer()
                PrimaryButton(title: next.isNil ? L10n.understand : L10n.next) {
                    if let next {
                        withAnimation { current = next.id }
                        app.post(event: story.next.tap, context: context)
                    } else {
                        app.post(event: story.finish.tap, context: context)
                    }
                }
                .padding(24.pt)
            }
            .tag(page.id)
        }
    }
}

extension StakingConsiderationsView {

    @MainActor
    public struct Page: View {

        @BlockchainApp var app
        @Environment(\.context) var context
        @Environment(\.isPreview) var isPreview

        @State var bondingDays: Int = 7

        public let id: Tag.Reference
        public let image: URL
        public let title: String
        public let message: String

        public var explain: I_blockchain_ux_transaction_disclaimer_explain {
            get throws { try id.tag.as(blockchain.ux.transaction.disclaimer.explain) }
        }
    }
}

extension StakingConsiderationsView.Page {

    static let formatter: DateComponentsFormatter = with(DateComponentsFormatter()) { formatter in
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day]
    }

    public var body: some View {
        VStack(spacing: 16.pt) {
            ZStack(alignment: .bottomTrailing) {
                AsyncMedia(url: image)
                    .frame(width: 90.pt, height: 90.pt)
                Icon.lockClosed.circle(backgroundColor: .semantic.background)
                    .frame(width: 38.pt, height: 38.pt)
                    .offset(x: 6.pt, y: 6.pt)
            }
            Text(title)
                .typography(.title3)
                .foregroundColor(.semantic.title)
            Text(message.interpolating(Self.formatter.string(from: DateComponents(day: bondingDays)) ?? "?"))
                .typography(.body1)
                .foregroundColor(.semantic.text)
            SmallMinimalButton(title: L10n.learnMore) {
                do {
                    try app.post(event: explain.learn.more.tap[].ref(to: id.context), context: context)
                } catch {
                    app.post(error: error)
                }
            }
        }
        .multilineTextAlignment(.center)
        .padding(24.pt)
        .onAppear {
            app.post(event: id, context: context)
        }
        .if(!isPreview) { view in // This breaks SwiftUI previews: https://github.com/apple/swift/issues/61133
            view.task {
                do {
                    bondingDays = try await app.get(blockchain.user.earn.product.asset.limit.days.bonding[].ref(to: context))
                } catch { /* ignored */ }
            }
        }
    }
}

public let stakingConsiderations = [
    StakingConsiderationsView.Page(
        id: blockchain.ux.transaction["staking-deposit"].disclaimer.explain["welcome"].key(),
        image: "https://www.blockchain.com/static/img/prices/prices-eth.svg",
        title: L10n.title,
        message: L10n.page.0
    ),
    StakingConsiderationsView.Page(
        id: blockchain.ux.transaction["staking-deposit"].disclaimer.explain["information"].key(),
        image: "https://www.blockchain.com/static/img/prices/prices-eth.svg",
        title: L10n.title,
        message: L10n.page.1
    ),
    StakingConsiderationsView.Page(
        id: blockchain.ux.transaction["staking-deposit"].disclaimer.explain["final"].key(),
        image: "https://www.blockchain.com/static/img/prices/prices-eth.svg",
        title: L10n.title,
        message: L10n.page.2
    )
]

struct StakingConsiderationsView_Previews: PreviewProvider {
    static var previews: some View {
        StakingConsiderationsView(pages: stakingConsiderations)
            .app(App.preview)
            .context(
                [
                    blockchain.ux.transaction.id: "staking-deposit",
                    blockchain.user.earn.product.id: "staking",
                    blockchain.user.earn.product.asset.id: "ETH"
                ]
            )
    }
}
