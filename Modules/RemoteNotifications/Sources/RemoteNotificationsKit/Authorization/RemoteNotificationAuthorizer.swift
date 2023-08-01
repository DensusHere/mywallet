// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import BlockchainNamespace
import Combine
import Extensions
import SwiftUI
import ToolKit
import UIKit
import UserNotifications

final class RemoteNotificationAuthorizer {

    // MARK: - Private Properties

    private let app: AppProtocol
    private let application: UIApplicationRemoteNotificationsAPI
    private let analyticsRecorder: AnalyticsEventRecorderAPI
    private let topMostViewControllerProvider: TopMostViewControllerProviding
    private let userNotificationCenter: UNUserNotificationCenterAPI
    private let options: UNAuthorizationOptions

    // MARK: - Setup

    init(
        app: AppProtocol,
        application: UIApplicationRemoteNotificationsAPI,
        analyticsRecorder: AnalyticsEventRecorderAPI,
        topMostViewControllerProvider: TopMostViewControllerProviding,
        userNotificationCenter: UNUserNotificationCenterAPI,
        options: UNAuthorizationOptions = [.alert, .badge, .sound]
    ) {
        self.app = app
        self.application = application
        self.analyticsRecorder = analyticsRecorder
        self.topMostViewControllerProvider = topMostViewControllerProvider
        self.userNotificationCenter = userNotificationCenter
        self.options = options
    }

    // MARK: - Private Accessors

    private func requestAuthorization() -> AnyPublisher<Void, RemoteNotificationAuthorizerError> {
        Deferred { [analyticsRecorder, userNotificationCenter, options] ()
            -> AnyPublisher<Void, RemoteNotificationAuthorizerError> in
            AnyPublisher<Void, RemoteNotificationAuthorizerError>
                .just(())
                .handleEvents(
                    receiveOutput: { _ in
                        analyticsRecorder.record(
                            event: AnalyticsEvents.Permission.permissionSysNotifRequest
                        )
                    }
                )
                .flatMap {
                    userNotificationCenter
                        .requestAuthorizationPublisher(
                            options: options
                        )
                        .mapError(RemoteNotificationAuthorizerError.system)
                }
                .handleEvents(
                    receiveOutput: { isGranted in
                        let event: AnalyticsEvents.Permission
                        if isGranted {
                            event = .permissionSysNotifApprove
                        } else {
                            event = .permissionSysNotifDecline
                        }
                        analyticsRecorder.record(event: event)
                    }
                )
                .flatMap { isGranted -> AnyPublisher<Void, RemoteNotificationAuthorizerError> in
                    guard isGranted else {
                        return .failure(.permissionDenied)
                    }
                    return .just(())
                }
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    private var isNotDetermined: AnyPublisher<Bool, Never> {
        status
            .map { $0 == .notDetermined }
            .eraseToAnyPublisher()
    }

    /// Checks if APNS token has been registered with our Push Provider
    private var unregistered: AnyPublisher<Bool, Never> {
        status
            .map { $0 == .authorized }
            .map { [app] authorized in
                let token = try? app.state.get(blockchain.ui.device.apns.token, as: String.self)
                return authorized && (token ?? "").isEmpty
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - RemoteNotificationAuthorizationStatusProviding

extension RemoteNotificationAuthorizer: RemoteNotificationAuthorizationStatusProviding {
    var status: AnyPublisher<UNAuthorizationStatus, Never> {
        Deferred { [userNotificationCenter] in
            Future { [userNotificationCenter] promise in
                userNotificationCenter.getAuthorizationStatus { status in
                    promise(.success(status))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - RemoteNotificationRegistering

extension RemoteNotificationAuthorizer: RemoteNotificationRegistering {
    func registerForRemoteNotificationsIfAuthorized() -> AnyPublisher<Void, RemoteNotificationAuthorizerError> {
        isAuthorized
            .flatMap { isAuthorized -> AnyPublisher<Void, RemoteNotificationAuthorizerError> in
                guard isAuthorized else {
                    return .failure(.unauthorizedStatus)
                }
                return .just(())
            }
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveOutput: { [unowned application] _ in
                    application.registerForRemoteNotifications()
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        Logger.shared
                            .error("Token registration failed with error: \(String(describing: error))")
                    case .finished:
                        break
                    }
                }
            )
            .eraseToAnyPublisher()
    }
}

// MARK: - RemoteNotificationAuthorizing

extension RemoteNotificationAuthorizer: RemoteNotificationAuthorizationRequesting {

    private var preauthorizedNotifications: AnyPublisher<Void, RemoteNotificationAuthorizerError> {
        app.on(blockchain.ux.onboarding.notification.authorization.accept.paragraph.button.primary.tap)
            .mapToVoid()
            .setFailureType(to: RemoteNotificationAuthorizerError.self)
            .eraseToAnyPublisher()
    }

    private var tokenUpdateIfNeeded: AnyPublisher<Void, RemoteNotificationAuthorizerError> {
        app
            .publisher(for: blockchain.user.id)
            .filter(\.value.isNotNil)
            .first()
            .flatMap { [isNotDetermined, unregistered] _ -> AnyPublisher<(Bool, Bool), Never> in
                isNotDetermined.withLatestFrom(unregistered) { ($0, $1) }
            }
            .flatMap { isNotDetermined, unregistered -> AnyPublisher<Bool, RemoteNotificationAuthorizerError> in
                guard isNotDetermined || unregistered else {
                    return .failure(.statusWasAlreadyDetermined)
                }
                return .just(unregistered)
            }
            .delay(for: .seconds(1), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .flatMap { [app] unregistered -> AnyPublisher<Void, RemoteNotificationAuthorizerError> in
                guard unregistered else {
                    app.post(
                        action: blockchain.ux.onboarding.notification.authorization.display.then.enter.into,
                        value: blockchain.ux.onboarding.notification.authorization.display,
                        context: [
                            blockchain.ui.type.action.then.enter.into.detents: [
                                blockchain.ui.type.action.then.enter.into.detents.large
                            ]
                        ]
                    )
                    return .empty()
                }
                return .just(())
            }
            .eraseToAnyPublisher()
    }

    // TODO: Handle a `.denied` case
    func requestAuthorizationIfNeeded() -> AnyPublisher<Void, RemoteNotificationAuthorizerError> {
        Publishers.Merge(preauthorizedNotifications, tokenUpdateIfNeeded)
            .flatMap { [requestAuthorization] _ in
                requestAuthorization()
            }
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveOutput: { [unowned application] _ in
                    application.registerForRemoteNotifications()
                },
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        Logger.shared
                            .error("Remote notification authorization failed with error: \(error)")
                    case .finished:
                        break
                    }
                }
            )
            .eraseToAnyPublisher()
    }
}

extension AnalyticsEvents {
    enum Permission: AnalyticsEvent {
        case permissionSysNotifRequest
        case permissionSysNotifApprove
        case permissionSysNotifDecline

        var name: String {
            switch self {
            // Permission - remote notification system request
            case .permissionSysNotifRequest:
                return "permission_sys_notif_request"
            // Permission - remote notification system approve
            case .permissionSysNotifApprove:
                return "permission_sys_notif_approve"
            // Permission - remote notification system decline
            case .permissionSysNotifDecline:
                return "permission_sys_notif_decline"
            }
        }
    }
}
