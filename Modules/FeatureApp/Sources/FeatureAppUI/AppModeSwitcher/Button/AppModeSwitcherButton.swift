// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import Foundation
import SwiftUI

public struct AppModeSwitcherButton: View {
    private let action: () -> Void
    private let appMode: AppMode
    public init(
        appMode: AppMode,
        action: @escaping () -> Void
    ) {
        self.appMode = appMode
        self.action = action
    }

    public var body: some View {
        HStack {
            if appMode == .pkw {
                Icon
                    .wallet
                    .accentColor(.semantic.defi)
                    .frame(width: 20, height: 20)
            } else {
                Icon
                    .portfolio
                    .accentColor(.semantic.primary)
                    .frame(width: 20, height: 20)
            }

            Text(appMode.displayName)
                .typography(.body1)
                .foregroundColor(Color.WalletSemantic.title)

            Icon
                .chevronDown
                .accentColor(.semantic.muted)
                .frame(width: 16, height: 16)
        }
        .padding(.horizontal, Spacing.padding1)
        .frame(height: 32)
        .background(Color.WalletSemantic.light)
        .cornerRadius(100)
        .onTapGesture {
            action()
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        AppModeSwitcherButton(appMode: .trading, action: {})
    }
}
