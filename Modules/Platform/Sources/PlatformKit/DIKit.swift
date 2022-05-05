// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureAuthenticationDomain
import FeatureCardPaymentDomain
import MoneyKit
import NetworkKit
import ToolKit
import WalletPayloadKit

public protocol ERC20AssetFactoryAPI {
    func erc20Asset(erc20AssetModel: AssetModel) -> CryptoAsset
}

extension DependencyContainer {

    // MARK: - PlatformKit Module

    public static var platformKit = module {

        // MARK: - Clients

        factory { SettingsClient() as SettingsClientAPI }

        factory { SwapClient() as SwapClientAPI }

        factory { GeneralInformationClient() as GeneralInformationClientAPI }

        factory { UpdateWalletInformationClient() as UpdateWalletInformationClientAPI }

        factory { KYCClient() as KYCClientAPI }

        factory { SupportedAssetsRemoteService() as SupportedAssetsRemoteServiceAPI }

        factory { SupportedAssetsClient() as SupportedAssetsClientAPI }

        factory { SendEmailNotificationClient() as SendEmailNotificationClientAPI }

        // MARK: Exchange

        factory { ExchangeAccountsClient() as ExchangeAccountsClientAPI }

        // MARK: CustodialClient

        factory { CustodialClient() as CustodialPaymentAccountClientAPI }

        factory { CustodialClient() as CustodialPendingDepositClientAPI }

        factory { CustodialClient() as TradingBalanceClientAPI }

        // MARK: - Wallet

        factory { WalletNabuSynchronizerService() as WalletNabuSynchronizerServiceAPI }

        factory { () -> WalletRepositoryAPI in
            let walletRepositoryProvider: WalletRepositoryProvider = DIKit.resolve()
            return walletRepositoryProvider.repository as WalletRepositoryAPI
        }

        // MARK: - Secure Channel

        single { SecureChannelService() as SecureChannelAPI }

        single { BrowserIdentityService() }

        single { SecureChannelClient() as SecureChannelClientAPI }

        factory { SecureChannelMessageService() }

        // MARK: - Services

        single { KYCTiersService() as KYCTiersServiceAPI }

        single { KYCTiersService() as KYCVerificationServiceAPI }

        single { NabuUserService() as NabuUserServiceAPI }

        single { GeneralInformationService() as GeneralInformationServiceAPI }

        single { EmailVerificationService() as EmailVerificationServiceAPI }

        single { SwapActivityService() as SwapActivityServiceAPI }

        single { ExchangeAccountsProvider() as ExchangeAccountsProviderAPI }

        factory { ExchangeAccountStatusService() as ExchangeAccountStatusServiceAPI }

        factory { LinkedBanksFactory() as LinkedBanksFactoryAPI }

        single { Coincore() as CoincoreAPI }

        single { ReactiveWallet() as ReactiveWalletAPI }

        factory { BlockchainAccountProvider() as BlockchainAccountRepositoryAPI }

        factory { BlockchainAccountProvider() as BlockchainAccountProviding }

        single { WalletService() as WalletOptionsAPI }

        factory { CustodialPendingDepositService() as CustodialPendingDepositServiceAPI }

        factory { CustodialAddressService() as CustodialAddressServiceAPI }

        factory { () -> MaintenanceServicing in
            let service: WalletOptionsAPI = DIKit.resolve()
            return service
        }

        factory { CredentialsStore() as CredentialsStoreAPI }

        factory { NSUbiquitousKeyValueStore.default as UbiquitousKeyValueStore }

        single { TradingBalanceService() as TradingBalanceServiceAPI }

        factory { PriceService() as PriceServiceAPI }

        factory { () -> CurrencyConversionServiceAPI in
            CurrencyConversionService(priceService: DIKit.resolve())
        }

        factory { ExternalAssetAddressService() as ExternalAssetAddressServiceAPI }

        factory { BlockchainAccountFetcher() as BlockchainAccountFetching }

        factory { SendEmailNotificationService() as SendEmailNotificationServiceAPI }

        // MARK: - Settings

        single { SettingsService() as CompleteSettingsServiceAPI }

        factory { () -> FiatCurrencySettingsServiceAPI in
            let completeSettings: CompleteSettingsServiceAPI = DIKit.resolve()
            return completeSettings
        }

        factory { () -> EmailSettingsServiceAPI in
            let completeSettings: CompleteSettingsServiceAPI = DIKit.resolve()
            return completeSettings
        }

        factory { () -> SMSTwoFactorSettingsServiceAPI in
            let completeSettings: CompleteSettingsServiceAPI = DIKit.resolve()
            return completeSettings
        }

        factory { () -> EmailNotificationSettingsServiceAPI in
            let completeSettings: CompleteSettingsServiceAPI = DIKit.resolve()
            return completeSettings
        }

        // MARK: - KYC

        factory { KYCTierUpdatePollingService() as KYCTierUpdatePollingServiceAPI }

        // MARK: - ExchangeProvider

        single { ExchangeProvider() as ExchangeProviding }

        // MARK: - HistoricalFiatPriceProvider

        single { HistoricalFiatPriceProvider() as HistoricalFiatPriceProviding }
    }

    // MARK: - BuySellKit Module

    public static var buySellKit = module {

        // MARK: - Clients - General

        factory { APIClient() as SimpleBuyClientAPI }

        factory { () -> SupportedPairsClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client as SupportedPairsClientAPI
        }

        factory { () -> TradingPairsClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client as TradingPairsClientAPI
        }

        factory { () -> BeneficiariesClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client as BeneficiariesClientAPI
        }

        factory { () -> OrderDetailsClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client as OrderDetailsClientAPI
        }

        factory { () -> OrderCancellationClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client as OrderCancellationClientAPI
        }

        factory { () -> OrderCreationClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client as OrderCreationClientAPI
        }

        factory { () -> EligibilityClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client as EligibilityClientAPI
        }

        factory { () -> PaymentAccountClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client as PaymentAccountClientAPI
        }

        factory { () -> SuggestedAmountsClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client as SuggestedAmountsClientAPI
        }

        factory { () -> QuoteClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client
        }

        factory { () -> CardOrderConfirmationClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client
        }

        factory { () -> WithdrawalClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client as WithdrawalClientAPI
        }

        factory { () -> PaymentEligibleMethodsClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client as PaymentEligibleMethodsClientAPI
        }

        factory { () -> EligibleCardAcquirersAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client as EligibleCardAcquirersAPI
        }

        factory { () -> ApplePayClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client as ApplePayClientAPI
        }

        factory { () -> LinkedBanksClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client as LinkedBanksClientAPI
        }

        factory { () -> OrdersActivityClientAPI in
            let client: SimpleBuyClientAPI = DIKit.resolve()
            return client as OrdersActivityClientAPI
        }

        // MARK: - Services - General

        single {
            OrdersActivityService(
                client: DIKit.resolve(),
                fiatCurrencyService: DIKit.resolve(),
                priceService: DIKit.resolve(),
                enabledCurrenciesService: DIKit.resolve()
            ) as OrdersActivityServiceAPI
        }

        factory {
            OrderConfirmationService(
                analyticsRecorder: DIKit.resolve(),
                client: DIKit.resolve(),
                applePayService: DIKit.resolve()
            ) as OrderConfirmationServiceAPI
        }

        factory { OrderQuoteService() as OrderQuoteServiceAPI }

        factory { EventCache() }

        single { OrdersService() as OrdersServiceAPI }

        factory { PendingOrderDetailsService() as PendingOrderDetailsServiceAPI }

        factory { PendingOrderCompletionService() as PendingOrderCompletionServiceAPI }

        factory { OrderCancellationService() as OrderCancellationServiceAPI }

        factory { OrderCreationService() as OrderCreationServiceAPI }

        factory { PaymentAccountService() as PaymentAccountServiceAPI }

        single { SupportedPairsInteractorService() as SupportedPairsInteractorServiceAPI }

        single { TradingPairsService() as TradingPairsServiceAPI }

        factory { SupportedPairsService() as SupportedPairsServiceAPI }

        single { EligibilityService() as EligibilityServiceAPI }

        factory { SuggestedAmountsService() as SuggestedAmountsServiceAPI }

        single { LinkedBanksService() as LinkedBanksServiceAPI }

        factory { CardDeletionService() as PaymentMethodDeletionServiceAPI }

        // MARK: - Services - Payment Methods

        single { BeneficiariesServiceUpdater() as BeneficiariesServiceUpdaterAPI }

        single { BeneficiariesService() as BeneficiariesServiceAPI }

        single { PaymentMethodTypesService() as PaymentMethodTypesServiceAPI }

        single { EligiblePaymentMethodsService() as PaymentMethodsServiceAPI }

        // MARK: - Services - Linked Banks

        factory { LinkedBankActivationService() as LinkedBankActivationServiceAPI }
    }
}