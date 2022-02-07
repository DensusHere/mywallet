// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import ComposableArchitecture
import SwiftUI
import UIComponentsKit

struct OnboardingChecklistRow: View {

    enum Status {
        case incomplete
        case pending
        case complete
    }

    let item: OnboardingChecklist.Item
    let status: Status

    var body: some View {
        PrimaryRow(
            title: item.title,
            caption: status == .pending ? item.pendingDetail : item.detail,
            leading: {
                item.icon
                    .frame(width: 28, height: 28)
                    .accentColor(item.accentColor)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: Spacing.buttonBorderRadius)
                            .fill(item.backgroundColor)
                    )
                    .clipped()
            },
            trailing: {
                if status == .complete {
                    Icon.checkCircle
                        .frame(width: 24, height: 24)
                        .accentColor(.semantic.success)
                } else if status == .pending {
                    ProgressView(value: 0.25)
                        .progressViewStyle(IndeterminateProgressStyle())
                        .frame(width: 24, height: 24)
                } else {
                    Icon.chevronRight
                        .frame(width: 24, height: 24)
                        .accentColor(item.accentColor)
                }
            }
        )
        .padding(2) // to make content fit within rounded corners
        .background(
            RoundedRectangle(cornerRadius: Spacing.buttonBorderRadius)
                .fill(Color.semantic.background)
                .shadow(
                    color: .black.opacity(0.12),
                    radius: 2,
                    x: 1,
                    y: 1
                )
        )
    }
}

struct OnboardingRow_Previews: PreviewProvider {

    static var previews: some View {
        VStack(spacing: Spacing.padding1) {
            OnboardingChecklistRow(item: .verifyIdentity, status: .incomplete)
            OnboardingChecklistRow(item: .linkPaymentMethod, status: .pending)
            OnboardingChecklistRow(item: .buyCrypto, status: .complete)
        }
        .padding()
    }
}
