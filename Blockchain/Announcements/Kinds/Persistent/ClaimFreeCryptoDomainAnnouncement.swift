// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKit
import DIKit
import FeatureCryptoDomainDomain
import PlatformUIKit
import RxSwift
import ToolKit

final class ClaimFreeCryptoDomainAnnouncement: PersistentAnnouncement, ActionableAnnouncement {

    // MARK: - Types

    private typealias LocalizedString = LocalizationConstants.AnnouncementCards.ClaimFreeDomain

    // MARK: - Properties

    var viewModel: AnnouncementCardViewModel {
        let button = ButtonViewModel.primary(
            with: LocalizedString.button,
            background: .primaryButton
        )
        button.tapRelay
            .bind { [weak self] in
                guard let self = self else { return }
                self.analyticsRecorder.record(event: self.actionAnalyticsEvent)
                self.action()
            }
            .disposed(by: disposeBag)
        return AnnouncementCardViewModel(
            type: type,
            badgeImage: .init(
                image: .local(name: "card-icon-unstoppable", bundle: .main),
                contentColor: nil,
                backgroundColor: .clear,
                cornerRadius: .none,
                size: .edge(40)
            ),
            title: LocalizedString.title,
            description: LocalizedString.description,
            buttons: [button],
            dismissState: .dismissible { [weak self] in
                guard let self = self else { return }
                self.dismiss()
            },
            didAppear: { [weak self] in
                guard let self = self else { return }
                self.analyticsRecorder.record(
                    event: self.didAppearAnalyticsEvent
                )
            }
        )
    }

    var shouldShow: Bool {
        claimFreeDomainEnabled.value
    }

    let type = AnnouncementType.claimFreeCryptoDomain
    let featureFlagsService: FeatureFlagsServiceAPI
    let analyticsRecorder: AnalyticsEventRecorderAPI
    let claimEligibilityRepository: ClaimEligibilityRepositoryAPI
    let action: CardAnnouncementAction
    let dismiss: CardAnnouncementAction

    private var claimFreeDomainEnabled: Atomic<Bool> = .init(false)

    private let disposeBag = DisposeBag()

    // MARK: - Setup

    init(
        featureFlagsService: FeatureFlagsServiceAPI = resolve(),
        analyticsRecorder: AnalyticsEventRecorderAPI = resolve(),
        claimEligibilityRepository: ClaimEligibilityRepositoryAPI = resolve(),
        action: @escaping CardAnnouncementAction,
        dismiss: @escaping CardAnnouncementAction
    ) {
        self.featureFlagsService = featureFlagsService
        self.analyticsRecorder = analyticsRecorder
        self.claimEligibilityRepository = claimEligibilityRepository
        self.action = action
        self.dismiss = dismiss

        claimEligibilityRepository
            .checkClaimEligibility()
            .zip(
                featureFlagsService.isEnabled(.local(.blockchainDomains)),
                featureFlagsService.isEnabled(.remote(.blockchainDomains))
            )
            .map { localEnabled, remoteEnabled, isEligible in
                localEnabled && remoteEnabled && isEligible
            }
            .asSingle()
            .subscribe { [weak self] enabled in
                self?.claimFreeDomainEnabled.mutate { $0 = enabled }
            }
            .disposed(by: disposeBag)
    }
}
