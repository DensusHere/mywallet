// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import FeatureProductsDomain
import SwiftUI

struct SuperAppSwitcherView: View {
    var tradingModeEnabled: Bool
    @Binding var currentSelection: AppMode
    @BlockchainApp var app

    var body: some View {
        HStack(spacing: Spacing.padding4) {
            if tradingModeEnabled {
                MutliAppModeButton(
                    isSelected: .constant(currentSelection.isTrading),
                    appMode: .trading,
                    icon: Icon.blockchain,
                    action: {
                        app.post(event: blockchain.ux.multiapp.chrome.switcher.trading.paragraph.button.minimal.tap)
                        withAnimation(.easeInOut(duration: 0.2)) { currentSelection = .trading }
                    },
                    secondaryAction: {
                        app.post(event: blockchain.ux.onboarding.intro.event.show.tutorial.trading)
                    }
                )
                MutliAppModeButton(
                    isSelected: .constant(currentSelection.isDefi),
                    appMode: .pkw,
                    icon: nil,
                    action: {
                        app.post(event: blockchain.ux.multiapp.chrome.switcher.defi.paragraph.button.minimal.tap)
                        withAnimation(.easeInOut(duration: 0.2)) { currentSelection = .pkw }
                    },
                    secondaryAction: {
                        app.post(event: blockchain.ux.onboarding.intro.event.show.tutorial.defi)
                    }
                )
            }
        }
        .bindings {
            subscribe($currentSelection.removeDuplicates().animation(.easeInOut(duration: 0.2)), to: blockchain.app.mode)
        }
        .onChange(of: currentSelection) { newValue in
            app.state.set(blockchain.app.mode, to: newValue.rawValue)
        }
        .padding(.bottom, Spacing.padding1)
        .overlayPreferenceValue(SuperAppModePreferenceKey.self) { preferences in
            GeometryReader { proxy in
                if let selected = preferences.first(where: { $0.mode == currentSelection }) {
                    let frame = proxy[selected.anchor]

                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .frame(width: 16, height: 4)
                        .position(x: frame.midX, y: frame.maxY)
                        .foregroundColor(.white)
                        .padding(.top, 4)
                        .accessibilityHidden(true)
                }
            }
        }
    }
}

// MARK: MultiApp Mode Preferences

struct SuperAppModePreferences: Equatable {
    let mode: AppMode
    let anchor: Anchor<CGRect>
}

struct SuperAppModePreferenceKey: PreferenceKey {
    static let defaultValue = [SuperAppModePreferences]()
    static func reduce(
        value: inout [SuperAppModePreferences],
        nextValue: () -> [SuperAppModePreferences]
    ) {
        value.append(contentsOf: nextValue())
    }
}

// MARK: MultiApp Mode Button

// swiftlint:disable multiple_closures_with_trailing_closure
struct MutliAppModeButton: View {
    @Binding var isSelected: Bool

    let appMode: AppMode
    let icon: Icon?
    let action: () -> Void
    let secondaryAction: () -> Void

    init(
        isSelected: Binding<Bool>,
        appMode: AppMode,
        icon: Icon?,
        action: @escaping () -> Void,
        secondaryAction: @escaping () -> Void
    ) {
        _isSelected = isSelected
        self.appMode = appMode
        self.icon = icon
        self.action = action
        self.secondaryAction = secondaryAction
    }

    var body: some View {
        Button(action: {}) {
            HStack(spacing: Spacing.padding1) {
                if let icon {
                    icon
                        .micro()
                        .color(.white)
                }
                Text(appMode.title)
                    .typography(.title3)
                    .foregroundColor(.white)
            }
            .opacity(isSelected ? 1.0 : 0.5)
            .onTapGesture(perform: action)
            .onLongPressGesture(perform: secondaryAction)
        }
        .anchorPreference(
            key: SuperAppModePreferenceKey.self,
            value: .bounds,
            transform: { anchor in
                [SuperAppModePreferences(mode: appMode, anchor: anchor)]
            }
        )
    }
}

// MARK: - Previews

struct SuperAppSwitcherView_Previews: PreviewProvider {
    static var previews: some View {
        SuperAppSwitcherView(
            tradingModeEnabled: true,
            currentSelection: .constant(.trading)
        )
        .padding()
        .background(Color.gray)
    }
}
