// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import ComposableArchitecture
import DIKit
import FeatureDashboardUI
import FeatureProductsDomain
import SwiftUI

struct SuperAppContentViewSmallDevice: View {
    @Environment(\.isSmallDevice) var isSmallDevice

    @BlockchainApp var app
    let store: StoreOf<SuperAppContent>
    /// The current selected app mode
    @Binding var currentModeSelection: AppMode
    /// The content offset for the modal sheet
    @Binding var contentOffset: ModalSheetContext

    @State private var isDeFiOnly = true
    @State private var isExternalTradingEnabled = false
    private var isTradingEnabled: Bool { !isDeFiOnly }

    /// `True` when a pull to refresh is triggered, otherwise `false`
    @Binding var isRefreshing: Bool

    @State private var headerFrame: CGRect = .zero

    var body: some View {
        WithViewStore(store, observe: \.headerState, content: { viewStore in
            ZStack(alignment: .top) {
                SuperAppHeaderView(
                    store: store.scope(state: \.headerState, action: SuperAppContent.Action.header),
                    currentSelection: $currentModeSelection,
                    contentOffset: $contentOffset,
                    isRefreshing: $isRefreshing,
                    headerFrame: $headerFrame
                )
                .onAppear {
                    viewStore.send(.onAppear)
                }
                .onDisappear {
                    viewStore.send(.onDisappear)
                }
                .onAppear {
                    app.post(value: currentModeSelection.rawValue, of: blockchain.app.mode)
                }
                .onChange(of: currentModeSelection) { newValue in
                    app.post(value: newValue.rawValue, of: blockchain.app.mode)
                }
                .bindings {
                    subscribe($isDeFiOnly, to: blockchain.app.is.DeFi.only)
                }
                .onChange(of: isTradingEnabled) { newValue in
                    if currentModeSelection == .trading, newValue == false {
                        currentModeSelection = .pkw
                    }
                }
                .refreshable {
                    await viewStore.send(.refresh, while: \.isRefreshing)
                }
                SuperAppDashboardContentView(
                    currentModeSelection: $currentModeSelection,
                    isTradingEnabled: viewStore.state.tradingEnabled,
                    isExternalTradingEnabled: isExternalTradingEnabled,
                    store: store
                )
                .cornerRadius(Spacing.padding3, corners: [.topLeft, .topRight])
                .padding(.top, headerFrame.height)
                .introspectViewController(customize: { controller in
                    controller.view.backgroundColor = .clear
                })
                .frame(maxWidth: .infinity)
                .background(
                    Color.clear
                )
            }
        })
    }
}
