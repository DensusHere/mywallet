// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import FeatureSettingsDomain
import PlatformKit
import PlatformUIKit
import RxSwift
import ToolKit
import WalletPayloadKit

final class SecuritySectionPresenter: SettingsSectionPresenting {
    let sectionType: SettingsSectionType = .security

    var state: Observable<SettingsSectionLoadingState> {
        let items: [SettingsCellViewModel] = [
            .init(cellType: .switch(.sms2FA, smsTwoFactorSwitchCellPresenter)),
            .init(cellType: .switch(.cloudBackup, cloudBackupSwitchCellPresenter)),
            .init(cellType: .common(.changePassword)),
            .init(cellType: .badge(.recoveryPhrase, recoveryCellPresenter)),
            .init(cellType: .common(.changePIN)),
            .init(cellType: .switch(.bioAuthentication, bioAuthenticationCellPresenter)),
            .init(cellType: .common(.userDeletion))
        ]
        let state = SettingsSectionViewModel(sectionType: sectionType, items: items)
        return .just(.loaded(next: .some(state)))
    }

    private let recoveryCellPresenter: RecoveryStatusCellPresenter
    private let bioAuthenticationCellPresenter: BioAuthenticationSwitchCellPresenter
    private let smsTwoFactorSwitchCellPresenter: SMSTwoFactorSwitchCellPresenter
    private let cloudBackupSwitchCellPresenter: CloudBackupSwitchCellPresenter

    init(
        smsTwoFactorService: SMSTwoFactorSettingsServiceAPI,
        credentialsStore: CredentialsStoreAPI,
        biometryProvider: BiometryProviding,
        settingsAuthenticater: AppSettingsAuthenticating,
        recoveryPhraseStatusProvider: RecoveryPhraseStatusProviding,
        authenticationCoordinator: AuthenticationCoordinating,
        cloudSettings: CloudBackupConfiguring = resolve()
    ) {
        smsTwoFactorSwitchCellPresenter = SMSTwoFactorSwitchCellPresenter(
            service: smsTwoFactorService
        )
        bioAuthenticationCellPresenter = BioAuthenticationSwitchCellPresenter(
            biometryProviding: biometryProvider,
            appSettingsAuthenticating: settingsAuthenticater,
            authenticationCoordinator: authenticationCoordinator
        )
        recoveryCellPresenter = RecoveryStatusCellPresenter(
            recoveryStatusProviding: recoveryPhraseStatusProvider
        )
        cloudBackupSwitchCellPresenter = CloudBackupSwitchCellPresenter(
            cloudSettings: cloudSettings,
            credentialsStore: credentialsStore
        )
    }
}
