// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import ComposableArchitecture
import FeatureCardIssuingDomain
import Localization
import MoneyKit
import SceneKit
import SwiftUI
import ToolKit
import WebKit

struct CardManagementView: View {

    private let localizedStrings = LocalizationConstants.CardIssuing.Manage.self

    private let store: Store<CardManagementState, CardManagementAction>

    init(store: Store<CardManagementState, CardManagementAction>) {
        self.store = store
    }

    var body: some View {
        WithViewStore(store.scope(state: \.error)) { viewStore in
            switch viewStore.state {
            case .some(let error):
                ErrorView(
                    error: error,
                    cancelAction: {
                        viewStore.send(.close)
                    }
                )
            default:
                content
            }
        }
    }

    @ViewBuilder var content: some View {
        // swiftlint:disable closure_body_length
        WithViewStore(store) { viewStore in
            ScrollView {
                LazyVStack {
                    HStack {
                        Text(localizedStrings.title)
                            .typography(.body2)
                        Spacer()
                        SmallMinimalButton(
                            title: localizedStrings.Button.manage,
                            action: {
                                viewStore.send(.showManagementDetails)
                            }
                        )
                    }
                    .padding(Spacing.padding2)
                    card
                    VStack {
                        AccountRow(account: viewStore.state.linkedAccount) {
                            viewStore.send(.showSelectLinkedAccountFlow)
                        }
                        PrimaryDivider()
                        HStack {
                            PrimaryButton(
                                title: localizedStrings.Button.addFunds,
                                action: {
                                    viewStore.send(.binding(.set(\.$isTopUpPresented, true)))
                                }
                            )
                            MinimalButton(
                                title: localizedStrings.Button.changeSource,
                                action: {
                                    viewStore.send(.showSelectLinkedAccountFlow)
                                }
                            )
                        }
                        .padding(Spacing.padding2)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.padding1)
                            .stroke(Color.semantic.light, lineWidth: 1)
                    )
                    .padding(Spacing.padding2)
                    VStack {
                        HStack {
                            Text(localizedStrings.RecentTransactions.title)
                                .typography(.body2)
                            Spacer()
                            SmallMinimalButton(title: localizedStrings.Button.seeAll) {
                                viewStore.send(
                                    .binding(
                                        .set(
                                            \.$isTransactionListPresented,
                                            true
                                        )
                                    )
                                )
                            }
                        }
                        .padding(.horizontal, Spacing.padding2)
                        VStack(spacing: 0) {
                            PrimaryDivider()
                            ForEach(viewStore.state.transactions.prefix(3)) { transaction in
                                ActivityRow(transaction) {
                                    viewStore.send(.showTransaction(transaction))
                                }
                                PrimaryDivider()
                            }
                        }
                    }
                    Text(localizedStrings.disclaimer)
                        .typography(.caption1.regular())
                        .multilineTextAlignment(.center)
                        .padding(Spacing.padding4)
                        .foregroundColor(.semantic.muted)
                }
                .listStyle(PlainListStyle())
                .background(Color.semantic.background.ignoresSafeArea())
            }
            .onAppear { viewStore.send(.onAppear) }
            .onDisappear { viewStore.send(.onDisappear) }
            .navigationTitle(
                LocalizationConstants
                    .CardIssuing
                    .Navigation
                    .title
            )
            .bottomSheet(
                isPresented: viewStore.binding(\.$isTopUpPresented),
                content: { topUpSheet }
            )
            .sheet(
                isPresented: viewStore.binding(\.$isDetailScreenVisible),
                content: { CardManagementDetailsView(store: store) }
            )
            .bottomSheet(
                isPresented: viewStore.binding(
                    get: {
                        $0.displayedTransaction != nil
                    },
                    send: CardManagementAction.setTransactionDetailsVisible
                ),
                content: {
                    ActivityDetailsView(store: store.scope(state: \.displayedTransaction))
                }
            )
            PrimaryNavigationLink(
                destination: ActivityListView(store: store),
                isActive: viewStore.binding(\.$isTransactionListPresented),
                label: EmptyView.init
            )
        }
    }

    @ViewBuilder var card: some View {
        ZStack(alignment: .center) {
            WithViewStore(store.scope(state: \.cardHelperUrl)) { viewStore in
                if let url = viewStore.state {
                    WebView(
                        url: url,
                        didLoad: {
                            viewStore.send(.cardHelperDidLoad)
                        }
                    )
                    .frame(width: 305, height: 205)
                }
            }
            WithViewStore(store.scope(state: \.cardHelperIsReady)) { viewStore in
                if !viewStore.state {
                    ProgressView(value: 0.25)
                        .progressViewStyle(.indeterminate)
                        .frame(width: 52, height: 52)
                }
            }
        }
        .frame(height: 205)
    }

    @ViewBuilder var topUpSheet: some View {
        WithViewStore(store.stateless) { viewStore in
            VStack {
                PrimaryDivider().padding(.top, Spacing.padding2)
                PrimaryRow(
                    title: localizedStrings.TopUp.AddFunds.title,
                    subtitle: localizedStrings.TopUp.AddFunds.caption,
                    leading: {
                        Icon.plus
                            .accentColor(.semantic.primary)
                            .frame(maxHeight: 24.pt)
                    },
                    action: {
                        viewStore.send(.openBuyFlow)
                    }
                )
                PrimaryDivider()
                PrimaryRow(
                    title: localizedStrings.TopUp.Swap.title,
                    subtitle: localizedStrings.TopUp.Swap.caption,
                    leading: {
                        Icon.plus
                            .accentColor(.semantic.primary)
                            .frame(maxHeight: 24.pt)
                    },
                    action: {
                        viewStore.send(.openSwapFlow)
                    }
                )
            }
        }
    }
}

struct AccountRow: View {

    let account: AccountSnapshot?
    let action: () -> Void

    private let localizedStrings = LocalizationConstants.CardIssuing.Manage.self

    init(account: AccountSnapshot?, action: @escaping () -> Void) {
        self.account = account
        self.action = action
    }

    var body: some View {
        if let account = account {
            BalanceRow(
                leadingTitle: account.name,
                leadingDescription: account.leadingDescription,
                trailingTitle: account.fiat.displayString,
                trailingDescription: account.trailingDescription,
                trailingDescriptionColor: .semantic.muted,
                action: action,
                leading: {
                    ZStack {
                        RoundedRectangle(cornerRadius: account.cornerRadius)
                            .frame(width: 24, height: 24)
                            .foregroundColor(account.backgroundColor)
                        account.image
                            .resizable()
                            .frame(width: account.iconWidth, height: account.iconWidth)
                    }
                }
            )
        } else {
            PrimaryRow(
                title: localizedStrings.Button.ChoosePaymentMethod.title,
                subtitle: localizedStrings.Button.ChoosePaymentMethod.caption,
                leading: {
                    Icon.questionCircle
                        .frame(width: 24)
                        .accentColor(
                            .semantic.muted
                        )
                },
                trailing: { chevronRight },
                action: action
            )
        }
    }

    @ViewBuilder var chevronRight: some View {
        Icon.chevronRight
            .frame(width: 18, height: 18)
            .accentColor(
                .semantic.muted
            )
            .flipsForRightToLeftLayoutDirection(true)
    }
}

final class WebView: NSObject, UIViewRepresentable, WKNavigationDelegate {

    let url: URL
    let didLoad: () -> Void

    init(url: URL, didLoad: @escaping () -> Void) {
        self.url = url
        self.didLoad = didLoad
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = self
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: url))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async { [weak self] in
            self?.didLoad()
        }
    }
}

#if DEBUG
struct CardManagement_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CardManagementView(
                store: Store(
                    initialState: .init(),
                    reducer: cardManagementReducer,
                    environment: .preview
                )
            )
        }
    }
}
#endif

extension AccountSnapshot {
    fileprivate var leadingDescription: String {
        cryptoCurrency?.name ?? LocalizationConstants.CardIssuing.Manage.SourceAccount.cashBalance
    }

    fileprivate var trailingDescription: String {
        cryptoCurrency == nil ? crypto.displayCode : crypto.displayString
    }
}
