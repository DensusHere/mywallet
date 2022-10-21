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

    @State private var isHelperReady: Bool = false

    private typealias L10n = LocalizationConstants.CardIssuing.Manage

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
        WithViewStore(store) { viewStore in
            ScrollView {
                LazyVStack {
                    HStack {
                        Text(L10n.title)
                            .typography(.body2)
                        Spacer()
                        SmallMinimalButton(
                            title: L10n.Selector.myCards,
                            action: {
                                viewStore.send(.binding(.set(\.$isCardSelectorPresented, true)))
                            }
                        )
                    }
                    .padding(Spacing.padding2)
                    card
                    CardStatusView(store: store)
                    VStack {
                        AccountRow(account: viewStore.state.linkedAccount) {
                            viewStore.send(.showSelectLinkedAccountFlow)
                        }
                        PrimaryDivider()
                        HStack {
                            PrimaryButton(
                                title: L10n.Button.addFunds,
                                action: {
                                    viewStore.send(CardManagementAction.openBuyFlow)
                                }
                            )
                            MinimalButton(
                                title: L10n.Button.changeSource,
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
                            Text(L10n.RecentTransactions.title)
                                .typography(.body2)
                            Spacer()
                            SmallMinimalButton(title: L10n.Button.seeAll) {
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
                            ForEach(viewStore.state.recentTransactions.value?.prefix(3) ?? []) { transaction in
                                ActivityRow(transaction) {
                                    viewStore.send(.showTransaction(transaction))
                                }
                                PrimaryDivider()
                            }
                            transactionPlaceholder
                        }
                    }
                    Text(L10n.disclaimer)
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
                isPresented: viewStore.binding(\.$isCardSelectorPresented),
                content: {
                    CardSelectorView(store: store)
                }
            )
            .sheet(
                isPresented: viewStore.binding(\.$isDetailScreenVisible),
                content: {
                    PrimaryNavigationView {
                        CardManagementDetailsView(
                            store: store
                        )
                        .navigationBarHidden(true)
                    }
                }
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
            .sheet(
                isPresented: viewStore.binding(
                    get: {
                        guard case .loaded = $0.activationUrl else {
                            return false
                        }
                        return true
                    },
                    send: CardManagementAction.hideActivationWebview
                )
            ) {
                if case .loaded(let url) = viewStore.state.activationUrl {
                    WebView(
                        url: url,
                        finishUrl: WebView.CallbackUrl.activate,
                        forceFullScreen: true,
                        onFinish: {
                            viewStore.send(.hideActivationWebview)
                        }
                    )
                } else {
                    EmptyView()
                }
            }
            PrimaryNavigationLink(
                destination: ActivityListView(store: store),
                isActive: viewStore.binding(\.$isTransactionListPresented),
                label: EmptyView.init
            )
        }
    }

    @ViewBuilder var card: some View {
        ZStack(alignment: .center) {
            if !isHelperReady {
                ProgressView(value: 0.25)
                    .progressViewStyle(.indeterminate)
                    .frame(width: 52, height: 52)
            }
            IfLetStore(
                store.scope(state: \.cardHelperUrl),
                then: { store in
                    WithViewStore(store) { viewStore in
                        WebView(
                            url: viewStore.state,
                            loading: $isHelperReady,
                            callback: { event in
                                guard case .manage = event.type else {
                                    return
                                }
                                viewStore.send(CardManagementAction.showManagementDetails)
                            }
                        )
                        .frame(width: UIScreen.main.bounds.width, height: 355)
                    }
                },
                else: {
                    EmptyView()
                }
            )
        }
        .frame(height: 355)
    }

    @ViewBuilder var transactionPlaceholder: some View {
        WithViewStore(store) { viewStore in
            if !viewStore.state.recentTransactions.isLoading,
               viewStore.state.recentTransactions.value?.isEmpty ?? true
            {
                VStack(alignment: .center, spacing: Spacing.padding1) {
                    Image("empty-tx-graphic", bundle: .cardIssuing)
                    Text(L10n.RecentTransactions.Placeholder.title)
                        .typography(.title3)
                        .foregroundColor(.semantic.title)
                    Text(L10n.RecentTransactions.Placeholder.message)
                        .multilineTextAlignment(.center)
                        .typography(.body1)
                        .foregroundColor(.semantic.body)
                }
                .padding(Spacing.padding2)
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder var topUpSheet: some View {
        WithViewStore(store.stateless) { viewStore in
            VStack {
                PrimaryDivider().padding(.top, Spacing.padding2)
                PrimaryRow(
                    title: L10n.TopUp.AddFunds.title,
                    subtitle: L10n.TopUp.AddFunds.caption,
                    leading: {
                        Icon.plus
                            .color(.semantic.primary)
                            .frame(maxHeight: 24.pt)
                    },
                    action: {
                        viewStore.send(.openBuyFlow)
                    }
                )
                PrimaryDivider()
                PrimaryRow(
                    title: L10n.TopUp.Swap.title,
                    subtitle: L10n.TopUp.Swap.caption,
                    leading: {
                        Icon.plus
                            .color(.semantic.primary)
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

    private typealias L10n = LocalizationConstants.CardIssuing.Manage

    init(account: AccountSnapshot?, action: @escaping () -> Void) {
        self.account = account
        self.action = action
    }

    var body: some View {
        if let account {
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
                title: L10n.Button.ChoosePaymentMethod.title,
                subtitle: L10n.Button.ChoosePaymentMethod.caption,
                leading: {
                    Icon.questionCircle
                        .color(
                            .semantic.muted
                        )
                        .frame(width: 24)
                },
                trailing: { chevronRight },
                action: action
            )
        }
    }

    @ViewBuilder var chevronRight: some View {
        Icon.chevronRight
            .color(
                .semantic.muted
            )
            .frame(width: 18, height: 18)
            .flipsForRightToLeftLayoutDirection(true)
    }
}

#if DEBUG
struct CardManagement_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CardManagementView(
                store: Store(
                    initialState: .init(tokenisationCoordinator: .init(service: MockServices())),
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
