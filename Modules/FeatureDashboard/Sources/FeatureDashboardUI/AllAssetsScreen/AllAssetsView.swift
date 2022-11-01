import BlockchainComponentLibrary
import ComposableArchitecture
import FeatureDashboardDomain
import Localization
import SwiftUI

public struct AllAssetsView: View {
    @ObservedObject var viewStore: ViewStoreOf<FeatureAllAssets>
    let store: StoreOf<FeatureAllAssets>
    @Environment(\.presentationMode) private var presentationMode

    public init(store: StoreOf<FeatureAllAssets>) {
        self.store = store
        viewStore = ViewStore(store)
    }

    public var body: some View {
            PrimaryNavigationView {
                VStack {
                    searchBarSection
                    allAssetsSection
                }
                .background(Color.WalletSemantic.light)
                .primaryNavigation(leading: {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Icon.closev2
                    }
                }, trailing: {
                    Button {
                        viewStore.send(.onFilterTapped)
                    } label: {
                        Icon.multiAppFilter
                    }
                    .if(viewStore.showSmallBalancesFilterIsOn) { $0.highlighted() }
                })
                .primaryNavigation(title: LocalizationConstants.MultiApp.AllAssets.title)
            }
            .bottomSheet(
                isPresented: viewStore.binding(\.$filterPresented).animation(.spring()),
                content: {
                filterSheet
                }
            )
            .task {
                await viewStore.send(.onAppear).finish()
            }
    }

    private var searchBarSection: some View {
        SearchBar(
            text: viewStore.binding(\.$searchText),
            isFirstResponder: viewStore.binding(\.$isSearching),
            cancelButtonText: LocalizationConstants.MultiApp.AllAssets.cancelButton,
            placeholder: LocalizationConstants.MultiApp.AllAssets.searchPlaceholder
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
                    } else
                  {
                    ForEach(searchResults) { info in
                        SimpleBalanceRow(
                            leadingTitle: info.currency.name,
                            trailingTitle: info.fiatBalance?.quote.toDisplayString(includeSymbol: true),
                            trailingDescription: info.priceChangeString,
                            trailingDescriptionColor: info.priceChangeColor,
                            action: {
                                viewStore.send(.onAssetTapped(info))
                            },
                            leading: {
                                AsyncMedia(
                                    url: info.currency.assetModel.logoPngUrl
                            )
                            .resizingMode(.aspectFit)
                            .frame(width: 24.pt, height: 24.pt)
                            }
                        )
                        if info.id != viewStore.searchResults?.last?.id {
                           Divider()
                                .foregroundColor(.WalletSemantic.light)
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
                Text(LocalizationConstants.MultiApp.AllAssets.Filter.title)
                    .typography(.paragraph2)
                    .padding(.top, Spacing.padding1)

                HStack {
                    Text(LocalizationConstants.MultiApp.AllAssets.Filter.showSmallBalancesLabel)
                        .typography(.paragraph2)
                        .padding(.leading, Spacing.padding2)
                    Spacer()
                    PrimarySwitch(
                        accessibilityLabel: "",
                        isOn: viewStore.binding(\.$showSmallBalancesFilterIsOn)
                    )
                        .padding(.trailing, Spacing.padding2)
                        .padding(.vertical, Spacing.padding2)
                }
                .background(Color.WalletSemantic.light)
                .cornerRadius(16, corners: .allCorners)
                .padding(.horizontal, Spacing.padding2)

                PrimaryButton(title: LocalizationConstants.MultiApp.AllAssets.Filter.showButton) {
                    viewStore.send(.onConfirmFilterTapped)
                }
                .padding(.horizontal, Spacing.padding2)
                .padding(.vertical, Spacing.padding3)
            })
            .frame(maxWidth: .infinity)

            Button {
                viewStore.send(.onResetTapped)
            } label: {
                Text(LocalizationConstants.MultiApp.AllAssets.Filter.resetButton)
            }
            .typography(.body2)
            .padding(.top, Spacing.padding1)
            .padding(.trailing, Spacing.padding2)
        }
    }

    private var loadingSection: some View {
        Group {
            SimpleBalanceRow(leadingTitle: "", trailingDescription: nil, leading: {})
            Divider()
                 .foregroundColor(.WalletSemantic.light)
            SimpleBalanceRow(leadingTitle: "", trailingDescription: nil, leading: {})
            Divider()
                 .foregroundColor(.WalletSemantic.light)
            SimpleBalanceRow(leadingTitle: "", trailingDescription: nil, leading: {})
        }
    }

    private var noResultsView: some View {
        HStack(alignment: .center, content: {
            Text(LocalizationConstants.MultiApp.AllAssets.noResults)
                .padding(.vertical, Spacing.padding2)
        })
        .frame(maxWidth: .infinity)
        .background(Color.white)
    }
}

extension CryptoAssetInfo {
    var priceChangeString: String? {
        guard let delta else {
            return nil
        }
        var arrowString: String {
            if delta.isZero {
                return ""
            }
            if delta.isSignMinus {
                return "↓"
            }

            return "↑"
        }
        return "\(arrowString) \(delta) %"
    }

    var priceChangeColor: Color? {
        guard let delta else {
            return nil
        }
        return delta.isSignMinus || delta.isZero ? Color.WalletSemantic.body : Color.WalletSemantic.success
    }
}
