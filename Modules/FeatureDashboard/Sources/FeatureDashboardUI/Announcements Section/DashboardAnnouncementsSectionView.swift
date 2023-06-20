// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainUI
import ComposableArchitecture
import DIKit
import Foundation
import Localization
import SwiftUI

public struct DashboardAnnouncementsSectionView: View {
    @BlockchainApp var app
    @Environment(\.context) var context

    @ObservedObject var viewStore: ViewStoreOf<DashboardAnnouncementsSection>
    let store: StoreOf<DashboardAnnouncementsSection>

    public init(store: StoreOf<DashboardAnnouncementsSection>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            if !viewStore.isEmpty {
                VStack(spacing: 0) {
                    announcementsSection(viewStore)
                        .onAppear {
                            viewStore.send(.onAppear)
                        }
                }
                .batch {
                    set(
                        blockchain.ux.user.activity.all.entry.paragraph.row.tap.then.enter.into,
                        to: blockchain.ux.user.activity.all
                    )
                }
            } else {
                Spacer()
                    .frame(height: 0)
                    .onAppear {
                        viewStore.send(.onAppear)
                    }
            }
        })
    }

    @ViewBuilder
    func announcementsSection(_ viewStore: ViewStoreOf<DashboardAnnouncementsSection>) -> some View {
        VStack(spacing: 0) {
            ForEachStore(
                store.scope(
                    state: \.announcementsCards,
                    action: DashboardAnnouncementsSection.Action.onAnnouncementTapped(id:action:)
                )
            ) { rowStore in
                WithViewStore(rowStore.scope(state: \.announcement.id)) { _ in
                    DashboardAnnouncementRowView(store: rowStore)
                }
            }
        }
        .cornerRadius(16, corners: .allCorners)
        .padding(.horizontal, Spacing.padding2)
    }
}
