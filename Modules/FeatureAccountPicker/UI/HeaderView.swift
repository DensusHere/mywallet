// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import Localization
import SwiftUI
import UIComponentsKit

struct HeaderView: View {
    let viewModel: HeaderStyle
    @Binding var searchText: String?
    @Binding var isSearching: Bool
    @Binding var segmentedControlSelection: Tag

    var body: some View {
        switch viewModel {
        case .none:
            EmptyView()
        case .simple(
            subtitle: let subtitle,
            searchable: let searchable,
            switchable: let switchable,
            switchTitle: let switchTitle
        ):
            SimpleHeaderView(
                subtitle: subtitle,
                searchable: searchable,
                switchTitle: switchTitle,
                switchable: switchable,
                searchText: $searchText,
                isSearching: $isSearching,
                segmentedControlSelection: $segmentedControlSelection
            )
        case .normal(
            title: let title,
            subtitle: let subtitle,
            image: let image,
            tableTitle: let tableTitle,
            searchable: let searchable
        ):
            NormalHeaderView(
                title: title,
                subtitle: subtitle,
                image: image,
                tableTitle: tableTitle,
                searchable: searchable,
                searchText: $searchText,
                isSearching: $isSearching
            )
        }
    }
}

private struct NormalHeaderView: View {
    let title: String
    let subtitle: String?
    let image: Image?
    let tableTitle: String?
    let searchable: Bool

    @Binding var searchText: String?
    @Binding var isSearching: Bool

    private enum Layout {
        static let margins = EdgeInsets(top: 24, leading: 24, bottom: 0, trailing: 24)

        static let titleTopPadding: CGFloat = 18
        static let subtitleTopPadding: CGFloat = 8
        static let tableTitleTopPadding: CGFloat = 27
        static let dividerLineTopPadding: CGFloat = 8

        static let imageSize = CGSize(width: 32, height: 32)
        static let dividerLineHeight: CGFloat = 1
        static let titleFontSize: CGFloat = 20
        static let subtitleFontSize: CGFloat = 14
        static let tableTitleFontSize: CGFloat = 12
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !isSearching {
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        image?
                            .aspectRatio(contentMode: .fit)
                            .frame(width: Layout.imageSize.width, height: Layout.imageSize.height)
                            .padding(.top, Layout.margins.top)

                        Text(title)
                            .font(Font(weight: .semibold, size: Layout.titleFontSize))
                            .foregroundColor(.textTitle)
                            .padding(.top, Layout.titleTopPadding)
                        if let subtitle {
                            Text(subtitle)
                                .font(Font(weight: .medium, size: Layout.subtitleFontSize))
                                .foregroundColor(.textSubheading)
                                .padding(.top, Layout.subtitleTopPadding)
                        }
                    }
                    .padding(.leading, Layout.margins.leading)

                    Spacer()
                }
                .padding(.trailing, Layout.margins.trailing)
            }

            if searchable {
                SearchBar(text: $searchText, isActive: $isSearching)
                    .padding(.trailing, Layout.margins.trailing - 8)
                    .padding(.leading, 8)
            }
        }
        .padding(.bottom, Spacing.padding1)
        .background(Color.semantic.light.ignoresSafeArea(edges: .top))
        .animation(.easeInOut, value: isSearching)
    }
}

private struct SimpleHeaderView: View {
    let subtitle: String?
    let searchable: Bool
    let switchTitle: String?
    let switchable: Bool
    @Binding var searchText: String?
    @Binding var isSearching: Bool
    @Binding var segmentedControlSelection: Tag

    private enum Layout {
        static let dividerLineHeight: CGFloat = 1
        static let subtitleFontSize: CGFloat = 14
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let subtitle, !isSearching {
                Text(subtitle)
                    .font(Font(weight: .medium, size: Layout.subtitleFontSize))
                    .foregroundColor(.textSubheading)
                    .padding(.horizontal, Spacing.padding3)
                    .padding(.vertical, Spacing.padding1)
            }

            if searchable || switchable {
                VStack {
                    if switchable {
                        LargeSegmentedControl(
                            items: [
                                LargeSegmentedControl.Item(title: NonLocalizedConstants.defiWallets, identifier: blockchain.ux.asset.account.swap.segment.filter.defi[]),
                                LargeSegmentedControl.Item(title: LocalizationConstants.accounts,
                                                           icon: Icon.blockchain,
                                                           identifier: blockchain.ux.asset.account.swap.segment.filter.trading[])
                            ], selection: $segmentedControlSelection
                        )
                        .padding(.horizontal, Spacing.padding3)
                    }

                    if searchable {
                        SearchBar(text: $searchText, isActive: $isSearching)
                            .padding(.horizontal, Spacing.padding2)
                    }
                }
            } else {
                Rectangle()
                    .frame(height: Layout.dividerLineHeight)
                    .foregroundColor(.dividerLineLight)
            }
        }
        .background(Color.semantic.light.ignoresSafeArea(edges: .top))
    }
}

private struct SearchBar: UIViewRepresentable {
    @Binding var text: String?
    @Binding var isActive: Bool

    func makeUIView(context: Context) -> UISearchBar {
        let view = UISearchBar()
        view.searchBarStyle = .minimal
        view.barTintColor = UIColor(BlockchainComponentLibrary.Color.semantic.body)
        view.placeholder = LocalizationConstants.searchPlaceholder
        view.searchTextField.textColor = UIColor(BlockchainComponentLibrary.Color.semantic.body)
        view.searchTextField.layer.cornerRadius = Spacing.padding2
        view.searchTextField.backgroundColor = .white
        view.searchTextField.borderStyle = .none
        view.searchTextField.leftView = nil
        view.searchTextField.leftViewMode = .never
        view.searchTextField.rightView = UIImageView(image: Icon.search.uiImage)
        view.searchTextField.rightViewMode = .always
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
        uiView.searchTextField.leftView = nil
        uiView.searchTextField.leftViewMode = .never
        uiView.searchTextField.rightView = UIImageView(image: Icon.search.uiImage)
        uiView.searchTextField.rightViewMode = .always
        if isActive {
            uiView.becomeFirstResponder()
        } else {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(searchText: $text, isActive: $isActive)
    }

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var searchText: String?
        @Binding var isActive: Bool

        init(searchText: Binding<String?>, isActive: Binding<Bool>) {
            _searchText = searchText
            _isActive = isActive
            super.init()
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            self.searchText = searchText
        }

        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            isActive = true
            searchBar.setShowsCancelButton(true, animated: true)
        }

        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            searchBar.setShowsCancelButton(false, animated: true)
            isActive = false
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            isActive = false
        }

        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchText = nil
            searchBar.resignFirstResponder()
        }
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewContainer()
            .previewLayout(.sizeThatFits)
    }

    struct PreviewContainer: View {
        @State var searchText: String?
        @State var isSearching: Bool = false
        @State var segmentedControlSelection: Tag = blockchain.ux.asset.account.swap.segment.filter.defi[]

        var body: some View {
            HeaderView(
                viewModel: .normal(
                    title: "Receive Crypto Now",
                    subtitle: "Choose a Wallet to receive crypto to.",
                    image: ImageAsset.iconReceive.image,
                    tableTitle: nil,
                    searchable: true
                ),
                searchText: $searchText,
                isSearching: $isSearching,
                segmentedControlSelection: $segmentedControlSelection
            )
            .animation(.easeInOut, value: isSearching)
        }
    }
}
