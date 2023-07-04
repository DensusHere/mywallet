import BlockchainComponentLibrary
import BlockchainUI
import ComposableArchitecture
import FeatureDashboardDomain
import FeatureTransactionUI
import Localization
import SwiftUI

public struct AllAssetsSceneView: View {
    @BlockchainApp var app
    @Environment(\.context) var context
    @ObservedObject var viewStore: ViewStoreOf<AllAssetsScene>
    let store: StoreOf<AllAssetsScene>

    public init(store: StoreOf<AllAssetsScene>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    public var body: some View {
        VStack {
            searchBarSection
            allAssetsSection
        }
        .background(Color.WalletSemantic.light.ignoresSafeArea())
        .navigationBarHidden(true)
        .superAppNavigationBar(
            leading: {
                Button {
                    viewStore.send(.onFilterTapped)
                } label: {
                    Icon
                        .filterv2
                        .color(.WalletSemantic.title)
                        .small()
                }
                .if(viewStore.showSmallBalances) { $0.highlighted() }
            },
            title: {
                Text(LocalizationConstants.SuperApp.AllAssets.title)
                    .typography(.body2)
                    .foregroundColor(.semantic.title)
            },
            trailing: {
                IconButton(icon: .closev2.circle()) {
                    $app.post(event: blockchain.ux.user.assets.all.article.plain.navigation.bar.button.close.tap)
                }
                .frame(width: 24.pt, height: 24.pt)
            },
            scrollOffset: nil
        )
        .bottomSheet(
            isPresented: viewStore.binding(\.$filterPresented).animation(.spring()),
            content: {
                filterSheet
            }
        )
        .batch {
            set(blockchain.ux.user.assets.all.article.plain.navigation.bar.button.close.tap.then.close, to: true)
        }
        .onAppear {
            viewStore.send(.onAppear)
        }
    }

    private var searchBarSection: some View {
        SearchBar(
            text: viewStore.binding(\.$searchText),
            isFirstResponder: viewStore.binding(\.$isSearching),
            cancelButtonText: LocalizationConstants.SuperApp.AllAssets.cancelButton,
            placeholder: LocalizationConstants.SuperApp.AllAssets.searchPlaceholder
        )
        .frame(height: 48)
        .padding(.horizontal, Spacing.padding2)
        .padding(.vertical, Spacing.padding3)
    }

    private var allAssetsSection: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if let searchResults = viewStore.searchResults {
                    if searchResults.isEmpty {
                        noResultsView
                    } else {
                        ForEach(searchResults) { info in
                            if let balance = info.balance {
                                balance.rowView(viewStore.presentedAssetType == .custodial ? .delta : .quote)
                                    .onTapGesture {
                                        viewStore.send(.set(\.$isSearching, false))
                                        viewStore.send(.onAssetTapped(info))
                                    }
                                if info.id != viewStore.searchResults?.last?.id {
                                    PrimaryDivider()
                                }
                            }
                        }
                    }
                } else {
                    loadingSection
                }
            }
            .cornerRadius(16, corners: .allCorners)
            .padding(.horizontal, Spacing.padding2)
        }
    }

    private var filterSheet: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center, content: {
                Text(LocalizationConstants.SuperApp.AllAssets.Filter.title)
                    .typography(.paragraph2)
                    .padding(.top, Spacing.padding1)

                HStack {
                    Text(LocalizationConstants.SuperApp.AllAssets.Filter.showSmallBalancesLabel)
                        .typography(.paragraph2)
                        .padding(.leading, Spacing.padding2)
                    Spacer()
                    PrimarySwitch(
                        accessibilityLabel: "",
                        isOn: viewStore.binding(\.$showSmallBalances)
                    )
                    .padding(.trailing, Spacing.padding2)
                    .padding(.vertical, Spacing.padding2)
                }
                .background(Color.WalletSemantic.light)
                .cornerRadius(16, corners: .allCorners)
                .padding(.horizontal, Spacing.padding2)

                PrimaryButton(title: LocalizationConstants.SuperApp.AllAssets.Filter.showButton) {
                    viewStore.send(.onConfirmFilterTapped)
                }
                .padding(.horizontal, Spacing.padding2)
                .padding(.vertical, Spacing.padding3)
            })
            .frame(maxWidth: .infinity)

            Button {
                viewStore.send(.onResetTapped)
            } label: {
                Text(LocalizationConstants.SuperApp.AllAssets.Filter.resetButton)
            }
            .typography(.body2)
            .padding(.top, Spacing.padding1)
            .padding(.trailing, Spacing.padding2)
        }
    }

    private var loadingSection: some View {
        Group {
            SimpleBalanceRow(leadingTitle: "", trailingDescription: nil, leading: {})
            PrimaryDivider()
            SimpleBalanceRow(leadingTitle: "", trailingDescription: nil, leading: {})
            PrimaryDivider()
            SimpleBalanceRow(leadingTitle: "", trailingDescription: nil, leading: {})
        }
    }

    private var noResultsView: some View {
        HStack(alignment: .center, content: {
            Text(LocalizationConstants.SuperApp.AllAssets.noResults)
                .padding(.vertical, Spacing.padding2)
        })
        .frame(maxWidth: .infinity)
        .background(Color.semantic.background)
    }
}
