// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import ComposableArchitecture
import FeatureFormDomain
import FeatureFormUI
import Localization
import SwiftUI

private typealias LocalizedStrings = LocalizationConstants.NewKYC.Steps.PersonalInfo

struct PersonalInfoView: View {

    let store: Store<PersonalInfo.State, PersonalInfo.Action>

    var body: some View {
        WithViewStore(store) { viewStore in
            PrimaryForm(
                form: viewStore.binding(\.$form),
                submitActionTitle: LocalizedStrings.submitActionTitle,
                submitActionLoading: viewStore.formSubmissionState == .loading,
                submitAction: {
                    viewStore.send(.submit)
                },
                submitButtonMode: .submitButtonAlwaysEnabled,
                headerIcon: {
                    headerIcon
                }
            )
            .primaryNavigation(
                leading: {
                    Button {
                        viewStore.send(.close)
                    } label: {
                        Icon.chevronLeft
                            .frame(width: 16, height: 16)
                            .accentColor(.semantic.primary)
                    }
                },
                trailing: {
                    let isValid = viewStore.isValidForm
                    Button {
                        viewStore.send(.submit)
                    } label: {
                        Text(LocalizedStrings.submitActionTitle)
                            .typography(.paragraph2)
                            .foregroundColor(
                                isValid ? .semantic.primary : .semantic.primary.opacity(0.4)
                            )
                    }
                    .disabled(!isValid)
                }
            )
            .onAppear {
                viewStore.send(.onViewAppear)
            }
        }
    }

    var headerIcon: some View {
        Icon.user
            .accentColor(.semantic.primary)
            .frame(width: 32.pt, height: 32.pt)
    }
}

struct PersonalInfoView_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            PrimaryNavigationView {
                PersonalInfoView(store: .emptyPreview)
            }
            .navigationBarTitleDisplayMode(.inline)

            PrimaryNavigationView {
                PersonalInfoView(store: .filledPreview)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
