// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import Combine
import ComposableArchitecture
import DelegatedSelfCustodyDomain
import DIKit
import Errors
import FeatureDexData
import FeatureDexDomain
import Foundation
import MoneyKit
import SwiftUI

public struct DexMain: ReducerProtocol {
    @Dependency(\.dexService) var dexService

    let mainQueue: AnySchedulerOf<DispatchQueue> = .main
    let app: AppProtocol

    public var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Scope(state: \.source, action: /Action.sourceAction) {
            DexCell()
        }
        Scope(state: \.destination, action: /Action.destinationAction) {
            DexCell()
        }
        Scope(state: \.networkPickerState, action: /Action.networkSelectionAction) {
            NetworkPicker()
        }
        Reduce { state, action in
            switch action {
            case .onAppear:
                let balances = dexService.balances()
                    .receive(on: mainQueue)
                    .eraseToEffect(Action.onBalances)

                let supportedTokens = dexService.supportedTokens()
                    .receive(on: mainQueue)
                    .eraseToEffect(Action.onSupportedTokens)

                let availableNetworks = dexService
                    .availableNetworks()
                    .receive(on: mainQueue)
                    .eraseToEffect(Action.onAvailableNetworksFetched)

                return .merge(balances, supportedTokens, availableNetworks)

            case .didTapCloseInProgressCard:
                state.networkTransactionInProgressCard = false
                return .none

            case .didTapSettings:
                let settings = blockchain.ux.currency.exchange.dex.settings
                let detents = blockchain.ui.type.action.then.enter.into.detents
                app.post(
                    event: settings.tap,
                    context: [
                        settings.sheet.slippage: state.slippage,
                        detents: [detents.automatic.dimension]
                    ]
                )
                return .none

            case .didTapPreview:
                state.confirmation = DexConfirmation.State(quote: state.quote?.success)
                state.isConfirmationShown = true
                return .none
            case .didTapAllowance:
                let allowance = blockchain.ux.currency.exchange.dex.allowance
                let detents = blockchain.ui.type.action.then.enter.into.detents
                app.post(
                    event: allowance.tap,
                    context: [
                        allowance.sheet.currency: state.source.currency!.code,
                        detents: [detents.automatic.dimension]
                    ]
                )
                return .none

                // Supported Tokens
            case .onSupportedTokens(let result):
                switch result {
                case .success(let tokens):
                    state.destination.supportedTokens = tokens
                case .failure:
                    break
                }
                return .none

                // Balances
            case .onBalances(let result):
                switch result {
                case .success(let balances):
                    return EffectTask(value: .updateAvailableBalances(balances))
                case .failure:
                    return EffectTask(value: .updateAvailableBalances([]))
                }
            case .updateAvailableBalances(let availableBalances):
                state.availableBalances = availableBalances
                return .none

                // Quote
            case .refreshQuote:
                state.quoteFetching = true
                return .merge(
                    .cancel(id: CancellationID.allowanceFetch),
                    fetchQuote(with: state)
                        .receive(on: mainQueue)
                        .eraseToEffect(Action.onQuote)
                        .cancellable(id: CancellationID.quoteFetch, cancelInFlight: true)
                )
            case .onQuote(let result):
                _onQuote(with: &state, update: result)
                return EffectTask(value: .refreshAllowance)

                // Allowance
            case .refreshAllowance:
                guard let quote = state.quote?.success else {
                    return .none
                }
                return dexService
                    .allowance(app: app, currency: quote.sellAmount.currency)
                    .receive(on: mainQueue)
                    .eraseToEffect(Action.onAllowance)
                    .cancellable(id: CancellationID.allowanceFetch, cancelInFlight: true)

            case .onAllowance(let result):
                switch result {
                case .success(let allowance):
                    return EffectTask(value: .updateAllowance(allowance))
                case .failure:
                    return EffectTask(value: .updateAllowance(nil))
                }
            case .updateAllowance(let allowance):
                let willRefresh = allowance == .ok
                && state.allowance.result != .ok
                && state.quote?.success?.isValidated != true
                state.allowance.result = allowance
                if willRefresh {
                    return EffectTask(value: .refreshQuote)
                        .debounce(
                            id: CancellationID.quoteDebounce,
                            for: .milliseconds(100),
                            scheduler: mainQueue
                        )
                }
                return .none

            case .onAvailableNetworksFetched(.success(let networks)):
                let wasEmpty = state.availableNetworks.isEmpty
                state.availableNetworks = networks
                guard wasEmpty else {
                    return .none
                }
                state.currentNetwork = preselectNetwork(from: networks)
                guard let currentNetwork = state.currentNetwork else {
                    return .none
                }
                return dexService
                    .pendingActivity(currentNetwork)
                    .receive(on: mainQueue)
                    .eraseToEffect(Action.onPendingTransactionStatus)
                    .cancellable(id: CancellationID.pendingActivity, cancelInFlight: true)

            case .onAvailableNetworksFetched(.failure):
                return .none

            case .onTransaction(let result, let quote):
                switch result {
                case .success(let transactionId):
                    let dialog = dexSuccessDialog(quote: quote, transactionId: transactionId)
                    state.confirmation?.pendingTransaction?.status = .success(dialog, quote.buyAmount.amount.currency)
                    return .none
                case .failure(let error):
                    state.confirmation?.pendingTransaction?.status = .error(error)
                    return .none
                }

                // Confirmation Action
            case .confirmationAction(.confirm):
                if let quote = state.quote?.success {
                    let dialog = dexInProgressDialog(quote: quote)
                    let newState = PendingTransaction.State(
                        currency: quote.sellAmount.currency,
                        status: .inProgress(dialog)
                    )
                    state.confirmation?.pendingTransaction = newState
                    return dexService
                        .executeTransaction(quote: quote)
                        .receive(on: mainQueue)
                        .eraseToEffect { output in
                            Action.onTransaction(output, quote)
                        }
                }
                return .none
            case .confirmationAction:
                return .none

                // Source action
            case .sourceAction(.binding(\.$inputText)):
                _clearQuote(with: &state)
                return EffectTask.merge(
                    .cancel(id: CancellationID.allowanceFetch),
                    .cancel(id: CancellationID.quoteFetch),
                    EffectTask(value: .refreshQuote)
                        .debounce(
                            id: CancellationID.quoteDebounce,
                            for: .milliseconds(500),
                            scheduler: mainQueue
                        )
                )

            case .sourceAction(.didSelectCurrency(let balance)):
                state.destination.bannedToken = balance.currency
                _clearQuote(with: &state)
                return .cancel(id: CancellationID.quoteFetch)
            case .sourceAction:
                return .none
            case .dismissKeyboard:
                state.source.textFieldIsFocused = false
                return .none

                // Network Picker Action
            case .networkSelectionAction(.onNetworkSelected(let network)):
                state.isSelectNetworkShown = false
                state.currentNetwork = network
                state.networkTransactionInProgressCard = false
                return dexService
                    .pendingActivity(network)
                    .receive(on: mainQueue)
                    .eraseToEffect(Action.onPendingTransactionStatus)
                    .cancellable(id: CancellationID.pendingActivity, cancelInFlight: true)

            case .networkSelectionAction(.onDismiss):
                state.isSelectNetworkShown = false
                return .none

            case .networkSelectionAction:
                return .none

                // Destination action
            case .destinationAction(.didSelectCurrency):
                _clearQuote(with: &state)
                return .merge(
                    .cancel(id: CancellationID.allowanceFetch),
                    .cancel(id: CancellationID.quoteFetch),
                    EffectTask(value: .refreshQuote)
                        .debounce(
                            id: CancellationID.quoteDebounce,
                            for: .milliseconds(100),
                            scheduler: mainQueue
                        )
                )
            case .destinationAction:
                return .none
            case .onSelectNetworkTapped:
                state.isSelectNetworkShown = true
                return .none

            case .onPendingTransactionStatus(let value):
                state.networkTransactionInProgressCard = value
                return .none

                // Binding
            case .binding(\.allowance.$transactionHash):
                guard let quote = state.quote?.success else {
                    return .none
                }
                return dexService
                    .allowancePoll(app: app, currency: quote.sellAmount.currency)
                    .receive(on: mainQueue)
                    .eraseToEffect(Action.onAllowance)
                    .cancellable(id: CancellationID.allowanceFetch, cancelInFlight: true)
            case .binding(\.$defaultFiatCurrency):
                return .none
            case .binding(\.$slippage):
                return .none
            case .binding:
                return .none
            }
        }
        .ifLet(\.confirmation, action: /Action.confirmationAction) {
            DexConfirmation(app: app)
        }
    }
}

extension DexConfirmation.State.Quote {
    init?(quote: DexQuoteOutput?) {
        guard let quote else {
            return nil
        }
        guard let slippage = Double(quote.slippage) else {
            return nil
        }
        self = DexConfirmation.State.Quote(
            enoughBalance: true,
            from: DexConfirmation.State.Target(value: quote.sellAmount),
            minimumReceivedAmount: quote.buyAmount.minimum!,
            networkFee: quote.productFee, // TODO: @paulo: Fix this when value is added to response.
            productFee: quote.productFee,
            slippage: slippage,
            to: DexConfirmation.State.Target(value: quote.buyAmount.amount)
        )
    }
}

extension DexConfirmation.State {
    init?(quote: DexQuoteOutput?) {
        guard let quote = DexConfirmation.State.Quote(quote: quote) else {
            return nil
        }
        self.init(quote: quote)
    }
}

extension DexMain {

    func _clearQuote(with state: inout State) {
        _onQuote(with: &state, update: nil)
    }

    func _onQuote(with state: inout State, update quote: Result<DexQuoteOutput, UX.Error>?) {
        state.quoteFetching = false
        if let old = state.quote?.success, old.sellAmount.currency != quote?.success?.sellAmount.currency {
            state.allowance.result = nil
            state.allowance.transactionHash = nil
        }
        state.quote = quote
        if state.confirmation != nil {
            let newQuote = DexConfirmation.State.Quote(
                quote: quote?.success
            )
            state.confirmation?.newQuote = newQuote
        }
    }

    func fetchQuote(with state: State) -> AnyPublisher<Result<DexQuoteOutput, UX.Error>, Never> {
        quoteInput(with: state)
            .flatMap { input -> AnyPublisher<Result<DexQuoteOutput, UX.Error>, Never> in
                guard let input else {
                    return .just(.failure(UX.Error(error: QuoteError.notReady)))
                }
                return dexService.quote(input)
            }
            .eraseToAnyPublisher()
    }

    private func quoteInput(with state: State) -> AnyPublisher<DexQuoteInput?, Never> {
        guard let amount = state.source.amount else {
            return .just(nil)
        }
        guard let destination = state.destination.currency else {
            return .just(nil)
        }
        let skipValidation = state.allowance.result != .ok && !amount.currency.isCoin
        return dexService.receiveAddressProvider(app, amount.currency)
            .map { takerAddress in
                DexQuoteInput(
                    amount: amount,
                    destination: destination,
                    skipValidation: skipValidation,
                    slippage: state.slippage,
                    takerAddress: takerAddress
                )
            }
            .optional()
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
}

extension DexMain {
    enum CancellationID {
        case quoteDebounce
        case quoteFetch
        case allowanceFetch
        case pendingActivity
    }
}

private func dexInProgressDialog(quote: DexQuoteOutput) -> DexDialog {
    DexDialog(
        title: String(
            format: L10n.Execution.InProgress.title,
            quote.sellAmount.displayCode,
            quote.buyAmount.amount.displayCode
        ),
        status: .pending
    )
}

private func dexSuccessDialog(
    quote: DexQuoteOutput,
    transactionId: String
) -> DexDialog {
    DexDialog(
        title: String(
            format: L10n.Execution.Success.title,
            quote.sellAmount.displayCode,
            quote.buyAmount.amount.displayCode
        ),
        message: L10n.Execution.Success.body,
        buttons: [
            DexDialog.Button(
                title: "View on Explorer",
                action: .openURL(explorerURL(quote: quote, transactionId: transactionId))
            ),
            DexDialog.Button(
                title: "Done",
                action: .dismiss
            )
        ],
        status: .pending
    )
}

private func explorerURL(
    quote: DexQuoteOutput,
    transactionId: String
) -> URL? {
    let service = EnabledCurrenciesService.default
    guard let network = service.network(for: quote.sellAmount.currency) else {
        return nil
    }
    return URL(string: network.networkConfig.explorerUrl + "/" + transactionId)
}

private func preselectNetwork(from networks: [EVMNetwork]) -> EVMNetwork? {
    networks.first(where: { $0.networkConfig == .ethereum }) ?? networks.first
}
