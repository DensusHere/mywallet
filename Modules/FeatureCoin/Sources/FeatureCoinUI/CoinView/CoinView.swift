// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import Combine
import ComposableArchitecture
import ComposableArchitectureExtensions
import FeatureCoinDomain
import Localization
import SwiftUI
import ToolKit

public struct CoinView: View {

    let store: Store<CoinViewState, CoinViewAction>
    @BlockchainApp var app

    @Environment(\.context) var context

    public init(store: Store<CoinViewState, CoinViewAction>) {
        self.store = store
    }

    typealias Localization = LocalizationConstants.Coin

    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    header(viewStore)
                    accounts(viewStore)
                    about(viewStore)
                    Color.clear
                        .frame(height: Spacing.padding2)
                }
                if viewStore.accounts.isNotEmpty {
                    actions(viewStore)
                }
            }
            .primaryNavigation(
                leading: navigationLeadingView,
                title: viewStore.currency.name,
                trailing: {
                    dismiss(viewStore)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { viewStore.send(.onAppear) }
            .onDisappear { viewStore.send(.onDisappear) }
            .bottomSheet(
                item: viewStore.binding(\.$account).animation(.spring()),
                content: { account in
                    AccountSheet(
                        account: account,
                        isVerified: viewStore.kycStatus != .unverified,
                        onClose: {
                            withAnimation(.spring()) {
                                viewStore.send(.set(\.$account, nil))
                            }
                        }
                    )
                    .context([blockchain.ux.asset.account.id: account.id])
                }
            )
            .bottomSheet(
                item: viewStore.binding(\.$explainer).animation(.spring()),
                content: { account in
                    AccountExplainer(
                        account: account,
                        onClose: {
                            withAnimation(.spring()) {
                                viewStore.send(.set(\.$explainer, nil))
                            }
                        }
                    )
                    .context([blockchain.ux.asset.account.id: account.id])
                }
            )
        }
    }

    @ViewBuilder func header(_ viewStore: ViewStore<CoinViewState, CoinViewAction>) -> some View {
        GraphView(
            store: store.scope(state: \.graph, action: CoinViewAction.graph)
        )
    }

    @ViewBuilder func totalBalance() -> some View {
        WithViewStore(store) { viewStore in
            TotalBalanceView(
                currency: viewStore.currency,
                accounts: viewStore.accounts,
                trailing: {
                    WithViewStore(store) { viewStore in
                        if let isFavorite = viewStore.isFavorite {
                            IconButton(icon: isFavorite ? .favorite : .favoriteEmpty) {
                                viewStore.send(isFavorite ? .removeFromWatchlist : .addToWatchlist)
                            }
                        } else {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .frame(width: 28, height: 28)
                        }
                    }
                }
            )
        }
    }

    @ViewBuilder func accounts(_ viewStore: ViewStore<CoinViewState, CoinViewAction>) -> some View {
        VStack {
            if viewStore.error == .failedToLoad {
                AlertCard(
                    title: Localization.Accounts.Error.title,
                    message: Localization.Accounts.Error.message,
                    variant: .error,
                    isBordered: true
                )
                .padding([.leading, .trailing, .top], Spacing.padding2)
            } else if viewStore.currency.isTradable {
                totalBalance()
                if let status = viewStore.kycStatus {
                    AccountListView(
                        accounts: viewStore.accounts,
                        currency: viewStore.currency,
                        interestRate: viewStore.interestRate,
                        kycStatus: status
                    )
                }
            } else {
                totalBalance()
                AlertCard(
                    title: Localization.Label.Title.notTradable.interpolating(
                        viewStore.currency.name,
                        viewStore.currency.displayCode
                    ),
                    message: Localization.Label.Title.notTradableMessage.interpolating(
                        viewStore.currency.name,
                        viewStore.currency.displayCode
                    )
                )
                .padding([.leading, .trailing], Spacing.padding2)
            }
        }
    }

    @State private var isExpanded: Bool = false

    @ViewBuilder func about(_ viewStore: ViewStore<CoinViewState, CoinViewAction>) -> some View {
        if viewStore.assetInformation?.description.nilIfEmpty == nil, viewStore.assetInformation?.website == nil {
            EmptyView()
        } else {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.padding1) {
                    Text(
                        Localization.Label.Title.aboutCrypto
                            .interpolating(viewStore.currency.name)
                    )
                    .foregroundColor(.semantic.title)
                    .typography(.body2)
                    if let about = viewStore.assetInformation?.description {
                        Text(rich: about)
                            .lineLimit(isExpanded ? nil : 6)
                            .typography(.paragraph1)
                            .foregroundColor(.semantic.title)
                        if !isExpanded {
                            Button(
                                action: {
                                    withAnimation {
                                        isExpanded.toggle()
                                    }
                                },
                                label: {
                                    Text(Localization.Button.Title.readMore)
                                        .typography(.paragraph1)
                                        .foregroundColor(.semantic.primary)
                                }
                            )
                        }
                    }
                    if let url = viewStore.assetInformation?.website {
                        Spacer()
                        SmallMinimalButton(title: Localization.Link.Title.visitWebsite) {
                            app.post(
                                event: blockchain.ux.asset.bio.visit.website[].ref(to: context),
                                context: [blockchain.ux.asset.bio.visit.website.url[]: url]
                            )
                        }
                    }
                }
                .padding(Spacing.padding3)
            }
        }
    }

    @ViewBuilder func navigationLeadingView() -> some View {
        WithViewStore(store) { viewStore in
            if let url = viewStore.currency.assetModel.logoPngUrl {
                Backport.AsyncImage(
                    url: url,
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(12)
                    }, placeholder: {
                        Color.semantic.muted
                            .opacity(0.3)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(.circular)
                            )
                            .clipShape(Circle())
                    }
                )
                .frame(width: 24.pt, height: 24.pt)
            }
        }
    }

    @ViewBuilder func dismiss(_ viewStore: ViewStore<CoinViewState, CoinViewAction>) -> some View {
        IconButton(icon: .closev2.circle()) {
            viewStore.send(.dismiss)
        }
        .frame(width: 24.pt, height: 24.pt)
    }

    @ViewBuilder func actions(_ viewStore: ViewStore<CoinViewState, CoinViewAction>) -> some View {
        VStack {
            let actions = viewStore.actions
            if actions.isNotEmpty {
                VStack(spacing: 0) {
                    PrimaryDivider()

                    HStack {
                        ForEach(actions.indexed(), id: \.element.event) { index, action in
                            if index == actions.index(before: actions.endIndex) {
                                PrimaryButton(
                                    title: action.title,
                                    leadingView: { action.icon },
                                    action: {
                                        app.post(event: action.event[].ref(to: context))
                                    }
                                )
                            } else {
                                SecondaryButton(
                                    title: action.title,
                                    leadingView: { action.icon },
                                    action: {
                                        app.post(event: action.event[].ref(to: context))
                                    }
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

// swiftlint:disable type_name
struct CoinView_PreviewProvider: PreviewProvider {

    static var previews: some View {

        PrimaryNavigationView {
            CoinView(
                store: .init(
                    initialState: .init(
                        currency: .bitcoin,
                        kycStatus: .gold,
                        accounts: [
                            .preview.privateKey,
                            .preview.trading,
                            .preview.rewards
                        ],
                        isFavorite: true,
                        graph: .init(
                            interval: .day,
                            result: .success(.preview)
                        )
                    ),
                    reducer: coinViewReducer,
                    environment: .preview
                )
            )
            .app(App.preview)
        }
        .previewDevice("iPhone SE (2nd generation)")
        .previewDisplayName("Gold - iPhone SE (2nd generation)")

        PrimaryNavigationView {
            CoinView(
                store: .init(
                    initialState: .init(
                        currency: .bitcoin,
                        kycStatus: .gold,
                        accounts: [
                            .preview.privateKey,
                            .preview.trading,
                            .preview.rewards
                        ],
                        isFavorite: true,
                        graph: .init(
                            interval: .day,
                            result: .success(.preview)
                        )
                    ),
                    reducer: coinViewReducer,
                    environment: .preview
                )
            )
            .app(App.preview)
        }
        .previewDevice("iPhone 13 Pro Max")
        .previewDisplayName("Gold - iPhone 13 Pro Max")

        PrimaryNavigationView {
            CoinView(
                store: .init(
                    initialState: .init(
                        currency: .ethereum,
                        kycStatus: .silver,
                        accounts: [
                            .preview.privateKey,
                            .preview.trading,
                            .preview.rewards
                        ],
                        isFavorite: false,
                        graph: .init(
                            interval: .day,
                            result: .success(.preview)
                        )
                    ),
                    reducer: coinViewReducer,
                    environment: .preview
                )
            )
            .app(App.preview)
        }
        .previewDisplayName("Silver")

        PrimaryNavigationView {
            CoinView(
                store: .init(
                    initialState: .init(
                        currency: .nonTradeable,
                        kycStatus: .unverified,
                        accounts: [
                            .preview.rewards
                        ],
                        isFavorite: false,
                        graph: .init(
                            interval: .day,
                            result: .success(.preview)
                        )
                    ),
                    reducer: coinViewReducer,
                    environment: .preview
                )
            )
            .app(App.preview)
        }
        .previewDisplayName("Not Tradable")

        PrimaryNavigationView {
            CoinView(
                store: .init(
                    initialState: .init(
                        currency: .bitcoin,
                        kycStatus: .unverified,
                        accounts: [
                            .preview.privateKey
                        ],
                        isFavorite: false,
                        graph: .init(
                            interval: .day,
                            result: .success(.preview)
                        )
                    ),
                    reducer: coinViewReducer,
                    environment: .preview
                )
            )
            .app(App.preview)
        }
        .previewDisplayName("Unverified")

        PrimaryNavigationView {
            CoinView(
                store: .init(
                    initialState: .init(
                        currency: .stellar,
                        isFavorite: nil,
                        graph: .init(isFetching: true)
                    ),
                    reducer: coinViewReducer,
                    environment: .previewEmpty
                )
            )
            .app(App.preview)
        }
        .previewDisplayName("Loading")

        PrimaryNavigationView {
            CoinView(
                store: .init(
                    initialState: .init(
                        currency: .bitcoin,
                        kycStatus: .unverified,
                        error: .failedToLoad,
                        isFavorite: false,
                        graph: .init(
                            interval: .day,
                            result: .failure(.serverError(.badResponse))
                        )
                    ),
                    reducer: coinViewReducer,
                    environment: .previewEmpty
                )
            )
            .app(App.preview)
        }
        .previewDisplayName("Error")
    }
}
