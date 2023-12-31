// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import ComposableArchitecture
import Errors
import ErrorsUI
import FeatureAddressSearchDomain
import Localization
import SwiftUI
import ToolKit
import UIComponentsKit

struct AddressModificationView: View {

    private typealias L10n = LocalizationConstants.AddressSearch

    private let store: Store<
        AddressModificationState,
        AddressModificationAction
    >

    init(
        store: Store<
            AddressModificationState,
            AddressModificationAction
        >
    ) {
        self.store = store
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: .zero) {
                if !viewStore.isPresentedFromSearchView {
                    PrimaryNavigationView {
                        content
                    }
                    footer
                } else {
                    content
                    footer
                }
            }
            .background(Color.semantic.light.ignoresSafeArea())
        }
    }

    private var content: some View {
        WithViewStore(store) { viewStore in
            ScrollView {
                form
                .padding(.bottom, Spacing.padding3)
                .primaryNavigation()
                .trailingNavigationButton(.close, isVisible: !viewStore.isPresentedFromSearchView) {
                    viewStore.send(.cancelEdit)
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
                .alert(
                    store.scope(state: \.failureAlert),
                    dismiss: .dismissAlert
                )
            }
            .background(Color.semantic.light.ignoresSafeArea())
        }
    }

    private var form: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: Spacing.padding3) {
                header
                VStack(spacing: Spacing.padding1) {
                    Input(
                        text: viewStore.binding(\.$line1),
                        isFirstResponder: viewStore
                            .binding(\.$selectedInputField)
                            .equals(.line1),
                        label: L10n.Form.addressLine1,
                        placeholder: L10n.Form.Placeholder.line1,
                        defaultBorderColor: .clear,
                        state: viewStore.state.line1.isEmpty ? .error : .default,
                        onReturnTapped: {
                            viewStore.send(.binding(.set(\.$selectedInputField, .line2)))
                        }
                    )
                    .textContentType(.streetAddressLine1)
                    .autocorrectionDisabled()

                    Input(
                        text: viewStore.binding(\.$line2),
                        isFirstResponder: viewStore
                            .binding(\.$selectedInputField)
                            .equals(.line2),
                        label: L10n.Form.addressLine2,
                        placeholder: L10n.Form.Placeholder.line2,
                        defaultBorderColor: .clear,
                        onReturnTapped: {
                            viewStore.send(.binding(.set(\.$selectedInputField, .city)))
                        }
                    )
                    .textContentType(.streetAddressLine2)
                    .autocorrectionDisabled()

                    Input(
                        text: viewStore.binding(\.$city),
                        isFirstResponder: viewStore
                            .binding(\.$selectedInputField)
                            .equals(.city),
                        label: L10n.Form.city,
                        defaultBorderColor: .clear,
                        onReturnTapped: {
                            viewStore.send(.binding(.set(\.$selectedInputField, .state)))
                        }
                    )
                    .textContentType(.addressCity)
                    .autocorrectionDisabled()

                    HStack(spacing: Spacing.padding2) {
                        if viewStore.isStateFieldVisible {
                            Input(
                                text: viewStore.binding(\.$stateName),
                                isFirstResponder: viewStore
                                    .binding(\.$selectedInputField)
                                    .equals(.state),
                                label: L10n.Form.state,
                                defaultBorderColor: .clear,
                                onReturnTapped: {
                                    viewStore.send(.binding(.set(\.$selectedInputField, .zip)))
                                }
                            )
                            .disabled(true)
                            .textContentType(.addressState)
                            .autocorrectionDisabled()
                        }
                        Input(
                            text: viewStore.binding(\.$postcode),
                            isFirstResponder: viewStore
                                .binding(\.$selectedInputField)
                                .equals(.zip),
                            label: L10n.Form.zip,
                            defaultBorderColor: .clear,
                            onReturnTapped: {
                                viewStore.send(.binding(.set(\.$selectedInputField, nil)))
                            }
                        )
                        .textContentType(.postalCode)
                        .autocorrectionDisabled()
                    }
                    Input(
                        text: .constant(countryName(viewStore.state.country)),
                        isFirstResponder: .constant(false),
                        label: L10n.Form.country,
                        defaultBorderColor: .clear
                    )
                    .disabled(true)
                }
                .padding(.horizontal, Spacing.padding2)
            }
        }
    }

    private var footer: some View {
        WithViewStore(store) { viewStore in
            PrimaryButton(
                title: viewStore.saveButtonTitle ?? L10n.Buttons.save,
                isLoading: viewStore.state.loading
            ) {
                viewStore.send(.updateAddress)
            }
            .disabled(
                viewStore.state.line1.isEmpty
                || viewStore.state.postcode.isEmpty
                || viewStore.state.city.isEmpty
                || viewStore.state.country.isEmpty
            )
            .frame(alignment: .bottom)
            .padding([.horizontal, .bottom])
            .background(
                Rectangle()
                    .fill(Color.semantic.light)
                    .backgroundWithLightShadow
            )
        }
    }

    private var header: some View {
        WithViewStore(store) { viewStore in
            if let subtitle = viewStore.screenSubtitle {
                VStack(alignment: .leading, spacing: Spacing.padding1) {
                    HStack {
                        Text(viewStore.screenTitle)
                            .typography(.title3)
                        Spacer()
                    }
                    Text(subtitle)
                        .typography(.body1)
                        .foregroundColor(.semantic.body)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, Spacing.padding2)
            }
        }
    }
}

extension View {

    fileprivate func trailingNavigationButton(
        _ navigationButton: NavigationButton,
        isVisible: Bool,
        action: @escaping () -> Void
    ) -> some View {
        guard isVisible else { return AnyView(self) }
        return AnyView(navigationBarItems(
            trailing: HStack {
                navigationButton.button(action: action)
            }
        ))
    }
}

func countryName(_ code: String) -> String {
    let locale = NSLocale.current as NSLocale
    return locale.displayName(forKey: NSLocale.Key.countryCode, value: code) ?? ""
}

#if DEBUG
struct AddressModification_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddressModificationView(
                store: Store(
                    initialState: .init(
                        addressDetailsId: MockServices.addressId,
                        isPresentedFromSearchView: false
                    ),
                    reducer: AddressModificationReducer(
                        mainQueue: .main,
                        config: .init(title: "Title", subtitle: "Subtitle"),
                        addressService: MockServices(),
                        addressSearchService: MockServices(),
                        onComplete: { _ in }
                    )
                )
            )
        }
        .environment(\.navigationBarColor, .semantic.light)
    }
}
#endif
