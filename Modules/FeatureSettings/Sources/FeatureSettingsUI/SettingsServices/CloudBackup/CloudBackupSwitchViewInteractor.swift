// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitectureExtensions
import FeatureSettingsDomain
import PlatformKit
import PlatformUIKit
import RxCocoa
import RxRelay
import RxSwift

class CloudBackupSwitchViewInteractor: SwitchViewInteracting {

    typealias InteractionState = LoadingState<SwitchInteractionAsset>

    var state: Observable<InteractionState> {
        _ = setup
        return stateRelay.asObservable()
    }

    private(set) lazy var switchTriggerRelay: PublishRelay<Bool> = {
        let relay = PublishRelay<Bool>()
        relay
            .do(onNext: { [weak self] value in
                self?.updateCloudBackup(enabled: value)
            })
            .map { .loaded(next: .init(isOn: $0, isEnabled: true)) }
            .bindAndCatch(to: stateRelay)
            .disposed(by: disposeBag)
        return relay
    }()

    private let stateRelay = BehaviorRelay<InteractionState>(value: .loading)
    private let disposeBag = DisposeBag()
    private let cloudSettings: CloudBackupConfiguring
    private let credentialsStore: CredentialsStoreAPI
    private lazy var setup: Void = Observable
        .just(cloudSettings.cloudBackupEnabled)
        .map { .loaded(next: .init(isOn: $0, isEnabled: true)) }
        .bindAndCatch(to: stateRelay)
        .disposed(by: disposeBag)

    init(cloudSettings: CloudBackupConfiguring, credentialsStore: CredentialsStoreAPI) {
        self.cloudSettings = cloudSettings
        self.credentialsStore = credentialsStore
    }

    private func updateCloudBackup(enabled: Bool) {
        cloudSettings.cloudBackupEnabled = enabled
        if !enabled {
            credentialsStore.erase()
        }
    }
}
