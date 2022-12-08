// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Blockchain
import BlockchainUI
import FeatureStakingDomain
import SwiftUI

@MainActor
struct EarnListView<Header: View, Content: View>: View {

    @BlockchainApp var app
    @Environment(\.context) var context

    let hub: L & I_blockchain_ux_earn_type_hub
    let model: [Model]?
    let header: () -> Header
    let content: (L & I_blockchain_ux_earn_type_hub_product_asset, EarnProduct, CryptoCurrency, Bool) -> Content

    @StateObject private var state: SortedData

    init(
        hub: L & I_blockchain_ux_earn_type_hub,
        model: [Model]?,
        @ViewBuilder header: @escaping () -> Header = EmptyView.init,
        @ViewBuilder content: @escaping (L & I_blockchain_ux_earn_type_hub_product_asset, EarnProduct, CryptoCurrency, Bool) -> Content
    ) {
        self.hub = hub
        self.model = model
        self.header = header
        self.content = content
        _state = .init(wrappedValue: SortedData(hub: hub))
    }

    enum Filter: Hashable {
        case all, only(EarnProduct)
    }

    @State var products: [EarnProduct] = []
    @State var filter: Filter = .all
    @State var search: String = ""
    @State var isSearching: Bool = false
    @State var subscription: AnyCancellable?

    let fuzzyAlgorithm = FuzzyAlgorithm()
    var filtered: [Model] {
        state.value.filter { item in
            switch filter {
            case .all: return true
            case .only(let o): return item.product == o
            }
        }
        .filter { item in
            search.isEmpty
                || item.asset.code.distance(between: search, using: fuzzyAlgorithm) < 0.3
                || item.asset.name.distance(between: search, using: fuzzyAlgorithm) < 0.3
        }
    }

    var body: some View {
        ZStack {
            if model.isNotNilOrEmpty {
                list
            } else {
                BlockchainProgressView()
            }
        }
        .subscribe($products, to: blockchain.ux.earn.supported.products)
        .onChange(of: model) { model in
            state.update(model, app: app)
        }
        .post(lifecycleOf: hub.article.plain, update: model)
    }

    @ViewBuilder func searchField() -> some View {
        Input(
            text: $search.animation().didSet { search in
                app.state.set($app[hub.search.paragraph.input], to: search.nilIfEmpty)
                $app.post(value: search.nilIfEmpty, of: hub.search.paragraph.input.event.value.changed)
            },
            isFirstResponder: $isSearching.animation()
        )
        .typography(.body2)
        .overlay(accessoryOverlay, alignment: .trailing)
        .padding([.leading, .trailing])
        .textFieldStyle(.roundedBorder)
    }

    @ViewBuilder var accessoryOverlay: some View {
        if isSearching {
            Button(
                action: { clear() },
                label: { Icon.close.color(.white).circle(backgroundColor: .semantic.muted.opacity(0.5)) }
            )
            .padding(10.pt)
        }
    }

    var filters: [(String, Filter)] {
        products.reduce(into: []) { items, product in
            if state.count[product].isNotNil {
                items.append((product.title, .only(product)))
            }
        }
    }

    @ViewBuilder var segmentedControl: some View {
        PrimarySegmentedControl(
            items: [.init(title: L10n.all, identifier: .all)] + filters.map { title, filter in
                .init(title: title, identifier: filter)
            },
            selection: $filter.didSet { filter in
                app.state.set($app[hub.filter.paragraph.input], to: filter)
                $app.post(value: filter, of: hub.filter.paragraph.input.event.value.changed)
                hideKeyboard()
            }.animation()
        )
    }

    @ViewBuilder var list: some View {
        List {
            if !(Header.self is EmptyView.Type), !isSearching {
                header()
                    .padding(.top, 8.pt)
                    .offset(y: 8.pt)
                    .listRowInsets(.zero)
                    .backport.hideListRowSeparator()
            }
            Section(
                header: VStack {
                    if state.value.count > 5 {
                        searchField()
                    }
                    if model.isNotNilOrEmpty, filters.count > 1 {
                        segmentedControl
                    }
                }
                .background(Color.semantic.background)
                .listRowInsets(.zero)
                .backport.hideListRowSeparator(),
                content: {
                    if model.isNotNil, filtered.isEmpty {
                        VStack(alignment: .center) {
                            Spacer()
                            noResults
                            Spacer()
                        }
                        .backport.hideListRowSeparator()
                    }
                    ForEach(filtered, id: \.self) { item in
                        content(hub.product.asset, item.product, item.asset, item.isEligible)
                            .context(
                                [
                                    blockchain.user.earn.product.id: item.product.value,
                                    blockchain.user.earn.product.asset.id: item.asset.code,
                                    hub.product.id: item.product.value,
                                    hub.product.asset.id: item.asset.code
                                ]
                            )
                            .listRowInsets(.zero)
                            .backport.hideListRowSeparator()
                            .overlay(
                                Group {
                                    if #available(iOS 15, *) {
                                        Rectangle()
                                            .fill(Color.semantic.light)
                                            .frame(height: 1.pt)
                                            .frame(maxWidth: .infinity)
                                    }
                                },
                                alignment: .top
                            )
                    }
                }
            )
        }
        .listStyle(.plain)
        .overlay(
            LinearGradient(
                colors: [.semantic.background, .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 10.pt),
            alignment: .top
        )
    }

    @ViewBuilder var noResults: some View {
        Text(L10n.noResults)
            .typography(.subheading)
            .foregroundColor(.semantic.title)
        SmallMinimalButton(title: L10n.reset) {
            clear()
        }
        .padding()
    }

    func clear() {
        withAnimation { search = "" }
        hideKeyboard()
    }
}

struct Model: Hashable {
    let product: EarnProduct, asset: CryptoCurrency
    let marketCap: Double
    let isEligible: Bool
    let crypto: MoneyValue?, fiat: MoneyValue?
    let rate: Double
}

extension EarnListView {

    class SortedData: ObservableObject {

        @Published var value: [Model] = []
        @Published var count: [EarnProduct: Int] = [:]

        let hub: L & I_blockchain_ux_earn_type_hub

        init(hub: L & I_blockchain_ux_earn_type_hub) {
            self.hub = hub
        }

        func update(_ model: [Model]?, app: AppProtocol) {
            value = model.emptyIfNil.lazy.filter { [hub] item in
                switch hub {
                case blockchain.ux.earn.portfolio:
                    guard let balance = item.fiat else { return false }
                    if app.state.yes(if: blockchain.ux.user.account.preferences.small.balances.are.hidden), balance.isDust {
                        return false
                    }
                    return balance.isPositive
                case _:
                    return true
                }
            }
            .sorted(by: { $0.asset.name < $1.asset.name })
            .sorted(by: { $0.marketCap > $1.marketCap })
            .sorted(by: { lhs, rhs in
                switch hub {
                case blockchain.ux.earn.portfolio:
                    guard let lhs = lhs.fiat, let rhs = rhs.fiat else { return false }
                    return (try? lhs > rhs) ?? false
                case _:
                    return lhs.rate > rhs.rate
                }
            })
            .sorted(by: { lhs, rhs in
                lhs.isEligible && !rhs.isEligible
            })
            count = Dictionary(
                grouping: value,
                by: \.product
            )
            .mapValues(\.count)
        }
    }
}
