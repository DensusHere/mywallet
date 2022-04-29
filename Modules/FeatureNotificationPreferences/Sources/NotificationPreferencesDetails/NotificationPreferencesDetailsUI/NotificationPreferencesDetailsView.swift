// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import SwiftUI
import ComposableArchitecture
import BlockchainComponentLibrary
import Mocks

public struct NotificationPreferencesDetailsView: View {
    var store: Store<NotificationPreferencesDetailsState, NotificationPreferencesDetailsAction>
    @ObservedObject var viewStore: ViewStore<NotificationPreferencesDetailsState, NotificationPreferencesDetailsAction>
    
    public init(store: Store<NotificationPreferencesDetailsState, NotificationPreferencesDetailsAction>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerViewSection
            controlsViewSection()
            Spacer()
        }
        .padding(.horizontal, Spacing.padding3)
    }
}


extension NotificationPreferencesDetailsView {
   @ViewBuilder func controlsViewSection() -> some View {
        WithViewStore(store) { viewStore in
            let requiredMethods = viewStore.notificationPreference.requiredMethods.map {$0.method}
            
            let allMethods = (viewStore.notificationPreference.requiredMethods + viewStore.notificationPreference.optionalMethods)
                .uniqued { $0.id }
            
            VStack(spacing: 30) {
                ForEach(allMethods, id: \.self) { methodInfo in
                    switch methodInfo.method {
                    case .push:
                        controlView(label: methodInfo.title,
                                     mandatory: requiredMethods.contains(.push),
                                    isOn: viewStore.binding(\.$pushSwitch.isOn))
                        
                    case .email:
                         controlView(label: methodInfo.title,
                                     mandatory: requiredMethods.contains(.email),
                                     isOn: viewStore.binding(\.$emailSwitch.isOn))
                        
                    case .sms:
                         controlView(label: methodInfo.title,
                                     mandatory: requiredMethods.contains(.sms),
                                     isOn: viewStore.binding(\.$smsSwitch.isOn))
                        
                    case .inApp:
                         controlView(label: methodInfo.title,
                                     mandatory: requiredMethods.contains(.inApp),
                                     isOn: viewStore.binding(\.$inAppSwitch.isOn))
                        
                    }
                }
            }
            .padding(.top, 50)
        }
        .onDisappear {
            viewStore.send(.save)
        }
    }
    
    @ViewBuilder private func controlView(label: String,
                             mandatory: Bool,
                             isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .typography(.body1)
            Spacer()
            PrimarySwitch(variant: .blue,
                          accessibilityLabel: "Something",
                          isOn: isOn)
        }
    }
    
    private var headerViewSection: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: 2) {
                Text(viewStore.notificationPreference.title)
                    .typography(.title3)
                
                Text(viewStore.notificationPreference.preferenceDescription)
                    .typography(.paragraph1)
                    .foregroundColor(Color.WalletSemantic.body)
            }
        }
    }
}


struct NotificationPreferencesDetailsViewView_Previews: PreviewProvider {
    static var previews: some View {
        let notificationPreference = MockGenerator.marketingNotificationPreference
        PrimaryNavigationView {
            NotificationPreferencesDetailsView(
                store: .init(
                    initialState: .init(notificationPreference: notificationPreference),
                    reducer: notificationPreferencesDetailsReducer,
                    environment: NotificationPreferencesDetailsEnvironment())
                    )
                }
        }
    }
        
