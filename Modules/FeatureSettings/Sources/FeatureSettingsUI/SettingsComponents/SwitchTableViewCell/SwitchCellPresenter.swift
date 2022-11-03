// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureSettingsDomain
import Localization
import PlatformKit
import PlatformUIKit
import RxSwift
import ToolKit

protocol SwitchCellPresenting {
    var accessibility: Accessibility { get }
    var labelContentPresenting: LabelContentPresenting { get }
    var switchViewPresenting: SwitchViewPresenting { get }
}

class CloudBackupSwitchCellPresenter: SwitchCellPresenting {

    private typealias AccessibilityId = Accessibility.Identifier.Settings.SettingsCell.CloudBackup
    private typealias LocalizedString = LocalizationConstants.Settings

    let accessibility: Accessibility = .id(AccessibilityId.title)
    let labelContentPresenting: LabelContentPresenting
    let switchViewPresenting: SwitchViewPresenting

    init(cloudSettings: CloudBackupConfiguring, credentialsStore: CredentialsStoreAPI) {
        labelContentPresenting = DefaultLabelContentPresenter(
            knownValue: LocalizationConstants.Settings.cloudBackup,
            descriptors: .settings
        )
        switchViewPresenting = CloudBackupSwitchViewPresenter(
            cloudSettings: cloudSettings,
            credentialsStore: credentialsStore
        )
    }
}

class SMSTwoFactorSwitchCellPresenter: SwitchCellPresenting {

    private typealias AccessibilityId = Accessibility.Identifier.Settings.SettingsCell

    let accessibility: Accessibility = .id(AccessibilityId.TwoStepVerification.title)
    let labelContentPresenting: LabelContentPresenting
    let switchViewPresenting: SwitchViewPresenting

    init(service: SMSTwoFactorSettingsServiceAPI & SettingsServiceAPI) {
        labelContentPresenting = DefaultLabelContentPresenter(
            knownValue: LocalizationConstants.Settings.twoFactorAuthentication,
            descriptors: .settings
        )
        switchViewPresenting = SMSSwitchViewPresenter(service: service)
    }
}

class BioAuthenticationSwitchCellPresenter: SwitchCellPresenting {

    private typealias AccessibilityId = Accessibility.Identifier.Settings.SettingsCell

    let accessibility: Accessibility = .id(AccessibilityId.BioAuthentication.title)
    let labelContentPresenting: LabelContentPresenting
    let switchViewPresenting: SwitchViewPresenting

    init(
        biometryProviding: BiometryProviding,
        appSettingsAuthenticating: AppSettingsAuthenticating,
        authenticationCoordinator: AuthenticationCoordinating
    ) {
        labelContentPresenting = BiometryLabelContentPresenter(
            provider: biometryProviding,
            descriptors: .settings
        )
        switchViewPresenting = BiometrySwitchViewPresenter(
            provider: biometryProviding,
            settingsAuthenticating: appSettingsAuthenticating,
            authenticationCoordinator: authenticationCoordinator
        )
    }
}
