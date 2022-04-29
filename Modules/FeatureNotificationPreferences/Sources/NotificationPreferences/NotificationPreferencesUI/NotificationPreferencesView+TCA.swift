// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
import ComposableNavigation
import FeatureNotificationPreferencesDetailsUI
import FeatureNotificationPreferencesDomain
import Foundation
import NetworkError
import SwiftUI

// MARK: - State

public struct NotificationPreferencesState: Hashable, NavigationState {
    public enum ViewState: Equatable, Hashable {
        case loading
        case data(notificationDetailsState: [NotificationPreference])
        case error
    }

    public var route: RouteIntent<NotificationsSettingsRoute>?
    public var viewState: ViewState
    public var notificationDetailsState: NotificationPreferencesDetailsState?

    public var notificationPrefrences: [NotificationPreference]?

    public init(
        route: RouteIntent<NotificationsSettingsRoute>? = nil,
        notificationDetailsState: NotificationPreferencesDetailsState? = nil,
        viewState: ViewState
    ) {
        self.route = route
        self.notificationDetailsState = notificationDetailsState
        self.viewState = viewState
    }
}

// MARK: - Actions

public enum NotificationPreferencesAction: Equatable, NavigationAction {
    case onAppear
    case onReloadTap
    case onPreferenceSelected(NotificationPreference)
    case notificationDetailsChanged(NotificationPreferencesDetailsAction)
    case onFetchedSettings(Result<[NotificationPreference], NetworkError>)
    case route(RouteIntent<NotificationsSettingsRoute>?)
}

// MARK: - Routing

public enum NotificationsSettingsRoute: NavigationRoute {
    case showDetails

    public func destination(in store: Store<NotificationPreferencesState, NotificationPreferencesAction>) -> some View {
        switch self {

        case .showDetails:
            return IfLetStore(
                store.scope(
                    state: \.notificationDetailsState,
                    action: NotificationPreferencesAction.notificationDetailsChanged
                ),
                then: { store in
                    NotificationPreferencesDetailsView(store: store)
                }
            )
        }
    }
}

// MARK: - Main Reducer

let mainReducer = Reducer<
    NotificationPreferencesState,
    NotificationPreferencesAction,
    NotificationPreferencesEnvironment
>
.combine(
    notificationPreferencesDetailsReducer
        .optional()
        .pullback(
            state: \.notificationDetailsState,
            action: /NotificationPreferencesAction.notificationDetailsChanged,
            environment: { _ -> NotificationPreferencesDetailsEnvironment in
                NotificationPreferencesDetailsEnvironment()
            }
        ),
    notificationPreferencesReducer
)

// MARK: - First screen reducer

public let notificationPreferencesReducer = Reducer<
    NotificationPreferencesState,
    NotificationPreferencesAction,
    NotificationPreferencesEnvironment
> { state, action, environment in

    switch action {
    case .onAppear:
        return environment
            .notificationPreferencesRepository
            .fetchPreferences()
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(NotificationPreferencesAction.onFetchedSettings)

    case .route(let routeItent):
        state.route = routeItent
        return .none

    case .onReloadTap:
        state.viewState = .loading
        return environment
            .notificationPreferencesRepository
            .fetchPreferences()
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(NotificationPreferencesAction.onFetchedSettings)

    case .notificationDetailsChanged(let action):
        switch action {
        case .save:
            guard let preferences = state.notificationDetailsState?.updatedPreferences else { return .none }
            return environment
                .notificationPreferencesRepository
                .update(preferences: preferences)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map { _ in
                    NotificationPreferencesAction.onReloadTap
                }

        case .binding:
            return .none
        }

    case .onPreferenceSelected(let preference):
        state.notificationDetailsState = NotificationPreferencesDetailsState(notificationPreference: preference)
        return .none

    case .onFetchedSettings(let result):
        switch result {
        case .success(let preferences):
            state.viewState = .data(notificationDetailsState: preferences)
            return .none

        case .failure(let error):
            state.viewState = .error
            return .none
        }
    }
}

// MARK: - Environment

public struct NotificationPreferencesEnvironment {
    public let mainQueue: AnySchedulerOf<DispatchQueue>
    public let notificationPreferencesRepository: NotificationPreferencesRepositoryAPI

    public init(
        mainQueue: AnySchedulerOf<DispatchQueue>,
        notificationPreferencesRepository: NotificationPreferencesRepositoryAPI
    ) {
        self.mainQueue = mainQueue
        self.notificationPreferencesRepository = notificationPreferencesRepository
    }
}
