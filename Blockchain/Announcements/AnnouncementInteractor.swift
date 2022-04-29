// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import ERC20Kit
import FeatureAuthenticationDomain
import FeatureCryptoDomainDomain
import MoneyKit
import PlatformKit
import PlatformUIKit
import RxSwift
import RxToolKit
import ToolKit

/// The announcement interactor cross all the preliminary data
/// that is required to display announcements to the user
final class AnnouncementInteractor: AnnouncementInteracting {

    // MARK: - Services

    /// Returns announcement preliminary data, according to which the relevant
    /// announcement will be displayed
    var preliminaryData: Single<AnnouncementPreliminaryData> {
        guard wallet.isInitialized() else {
            return Single.error(AnnouncementError.uninitializedWallet)
        }

        let assetRename: Single<AnnouncementPreliminaryData.AssetRename?> = featureFetcher
            .fetch(for: .assetRenameAnnouncement, as: AssetRenameAnnouncementFeature.self)
            .eraseError()
            .flatMap { [enabledCurrenciesService, coincore] data
                -> AnyPublisher<AnnouncementPreliminaryData.AssetRename?, Error> in
                guard let cryptoCurrency = CryptoCurrency(
                    code: data.networkTicker,
                    enabledCurrenciesService: enabledCurrenciesService
                ) else {
                    return .just(nil)
                }
                return coincore[cryptoCurrency]
                    .accountGroup(filter: .all)
                    .flatMap(\.balancePublisher)
                    .map { balance in
                        AnnouncementPreliminaryData.AssetRename(
                            asset: cryptoCurrency,
                            oldTicker: data.oldTicker,
                            balance: balance
                        )
                    }
                    .eraseError()
                    .eraseToAnyPublisher()
            }
            .replaceError(with: nil)
            .asSingle()

        let hasLinkedBanks = beneficiariesService.hasLinkedBank
            .take(1)
            .asSingle()
        let isSimpleBuyAvailable = supportedPairsInteractor.pairs
            .map { !$0.pairs.isEmpty }
            .take(1)
            .asSingle()
        let isSimpleBuyEligible = simpleBuyEligibilityService.isEligible
        let simpleBuyOrderDetails = pendingOrderDetailsService.pendingActionOrderDetails

        let simpleBuy: Single<AnnouncementPreliminaryData.SimpleBuy> = Single
            .zip(
                hasLinkedBanks,
                isSimpleBuyAvailable,
                isSimpleBuyEligible,
                simpleBuyOrderDetails
            )
            .map { hasLinkedBanks, isSimpleBuyAvailable, isSimpleBuyEligible, simpleBuyOrderDetails in
                AnnouncementPreliminaryData.SimpleBuy(
                    hasLinkedBanks: hasLinkedBanks,
                    isAvailable: isSimpleBuyAvailable,
                    isEligible: isSimpleBuyEligible,
                    pendingOrderDetails: simpleBuyOrderDetails
                )
            }

        let nabuUser = userService.user.asSingle()
        let tiers = tiersService.tiers.asSingle()
        let sddEligibility = tiersService.checkSimplifiedDueDiligenceEligibility()
            .asSingle()
        let countries = infoService.countries

        let hasAnyWalletBalance = coincore.allAccounts
            .asSingle()
            .map(\.accounts)
            .flatMap { accounts -> Single<[Bool]> in
                Single.zip(accounts.map { $0.isFunded.catchAndReturn(false) })
            }
            .map { values in
                values.contains(true)
            }

        let authenticatorType = repository.authenticatorType.asSingle()
        let newAsset: Single<CryptoCurrency?> = featureFetcher
            .fetch(for: .newAssetAnnouncement, as: String.self)
            .map { [enabledCurrenciesService] code -> CryptoCurrency? in
                CryptoCurrency(
                    code: code,
                    enabledCurrenciesService: enabledCurrenciesService
                )
            }
            .replaceError(with: nil)
            .asSingle()

        let claimFreeDomainEligible = featureFetcher
            .fetch(for: .blockchainDomains, as: Bool.self)
            .flatMap { [claimEligibilityRepository] isEnabled in
                isEnabled ? claimEligibilityRepository.checkClaimEligibility() : .just(false)
            }
            .asSingle()

        return Single.zip(
            nabuUser,
            tiers,
            countries,
            authenticatorType,
            hasAnyWalletBalance,
            Single.zip(
                newAsset,
                assetRename,
                simpleBuy,
                sddEligibility,
                claimFreeDomainEligible
            )
        )
        .map { payload -> AnnouncementPreliminaryData in
            let (
                user,
                tiers,
                countries,
                authenticatorType,
                hasAnyWalletBalance,
                (
                    newAsset,
                    assetRename,
                    simpleBuy,
                    isSDDEligible,
                    claimFreeDomainEligible
                )
            ) = payload
            return AnnouncementPreliminaryData(
                assetRename: assetRename,
                authenticatorType: authenticatorType,
                claimFreeDomainEligible: claimFreeDomainEligible,
                countries: countries,
                hasAnyWalletBalance: hasAnyWalletBalance,
                isSDDEligible: isSDDEligible,
                newAsset: newAsset,
                simpleBuy: simpleBuy,
                tiers: tiers,
                user: user
            )
        }
        .observe(on: MainScheduler.instance)
    }

    // MARK: - Private properties

    private let beneficiariesService: BeneficiariesServiceAPI
    private let claimEligibilityRepository: ClaimEligibilityRepositoryAPI
    private let coincore: CoincoreAPI
    private let enabledCurrenciesService: EnabledCurrenciesServiceAPI
    private let featureFetcher: FeatureFetching
    private let infoService: GeneralInformationServiceAPI
    private let pendingOrderDetailsService: PendingOrderDetailsServiceAPI
    private let repository: AuthenticatorRepositoryAPI
    private let simpleBuyEligibilityService: EligibilityServiceAPI
    private let supportedPairsInteractor: SupportedPairsInteractorServiceAPI
    private let tiersService: KYCTiersServiceAPI
    private let userService: NabuUserServiceAPI
    private let wallet: WalletProtocol

    // MARK: - Setup

    init(
        beneficiariesService: BeneficiariesServiceAPI = resolve(),
        claimEligibilityRepository: ClaimEligibilityRepositoryAPI = resolve(),
        coincore: CoincoreAPI = resolve(),
        enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve(),
        featureFetcher: FeatureFetching = resolve(),
        infoService: GeneralInformationServiceAPI = resolve(),
        pendingOrderDetailsService: PendingOrderDetailsServiceAPI = resolve(),
        repository: AuthenticatorRepositoryAPI = resolve(),
        simpleBuyEligibilityService: EligibilityServiceAPI = resolve(),
        supportedPairsInteractor: SupportedPairsInteractorServiceAPI = resolve(),
        tiersService: KYCTiersServiceAPI = resolve(),
        userService: NabuUserServiceAPI = resolve(),
        wallet: WalletProtocol = WalletManager.shared.wallet
    ) {
        self.beneficiariesService = beneficiariesService
        self.claimEligibilityRepository = claimEligibilityRepository
        self.coincore = coincore
        self.enabledCurrenciesService = enabledCurrenciesService
        self.featureFetcher = featureFetcher
        self.infoService = infoService
        self.pendingOrderDetailsService = pendingOrderDetailsService
        self.repository = repository
        self.simpleBuyEligibilityService = simpleBuyEligibilityService
        self.supportedPairsInteractor = supportedPairsInteractor
        self.tiersService = tiersService
        self.userService = userService
        self.wallet = wallet
    }
}
