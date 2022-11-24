import Blockchain
import BlockchainComponentLibrary
import ComposableArchitecture
import ComposableArchitectureExtensions
import FeatureTransactionDomain
import Foundation
import Localization
import SwiftUI
import UIComponentsKit

struct RecurringBuyFrequencySelectorView: View {

    private typealias LocalizationId = LocalizationConstants.Transaction.Buy.Recurring.FrequencySelector

    private let store: Store<RecurringBuyFrequencySelectorState, RecurringBuyFrequencySelectorAction>

    init(store: Store<RecurringBuyFrequencySelectorState, RecurringBuyFrequencySelectorAction>) {
        self.store = store
    }

    var body: some View {
        WithViewStore(store) { viewStore in
            ActionableView(
                buttons: [
                    .init(
                        title: LocalizationConstants.okString,
                        action: {
                            viewStore.send(.okTapped)
                        },
                        style: .primary
                    )
                ],
                content: {
                    VStack {
                        closeHandle
                            .onTapGesture {
                                viewStore.send(.closeButtonTapped)
                            }
                        HStack {
                            Text(LocalizationId.title)
                                .typography(.title3)
                            Spacer()
                            IconButton(icon: .closev2.circle()) {
                                viewStore.send(.closeButtonTapped)
                            }
                            .frame(width: 24, height: 24)
                        }
                        .padding(.leading, 8.pt)
                        .padding(.bottom, 16.pt)
                        .padding(.top, 4.pt)

                        ForEach(viewStore.items) { value in
                            VStack {
                                HStack {
                                    VStack(alignment: .leading, spacing: 16.pt) {
                                        Text(value.frequency.description)
                                            .typography(.paragraph2)
                                            .foregroundColor(.textTitle)
                                        if let date = value.date {
                                            Text(date)
                                                .typography(.paragraph1)
                                                .foregroundColor(.textBody)
                                        }
                                    }
                                    Spacer()
                                    Radio(isOn: .constant(viewStore.recurringBuyFrequency == value.frequency))
                                }
                                .padding([.top, .bottom], 16.pt)

                                if value.frequency != viewStore.recurringBuyFrequencies.last {
                                    PrimaryDivider()
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewStore.send(.recurringBuyFrequencySelected(value.frequency))
                            }
                        }
                    }
                }
            )
            .onAppear {
                viewStore.send(.refresh)
            }
        }
    }

    private var closeHandle: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.semantic.medium)
            .frame(width: 32, height: 4)
            .padding(.top, Spacing.padding1)
            .padding(.bottom, 4.pt)
    }
}

struct RecurringBuyFrequencySelectorView_Previews: PreviewProvider {
    static var previews: some View {
        RecurringBuyFrequencySelectorView(
            store: .init(
                initialState: .init(eligibleRecurringBuyFrequenciesAndNextDates: []),
                reducer: recurringBuyFrequencySelectorReducer,
                environment: RecurringBuyFrequencySelectorEnvironment(app: App.preview, dismiss: {})
            )
        )
    }
}

// MARK: - Environment

struct RecurringBuyFrequencySelectorEnvironment {
    let app: AppProtocol
    let dismiss: (() -> Void)?
}

// MARK: - State

struct RecurringBuyFrequencySelectorState: Equatable {
    var recurringBuyFrequencies: [RecurringBuy.Frequency] {
        [.once] + eligibleRecurringBuyFrequenciesAndNextDates.map(\.frequency)
    }

    var items: [EligibleAndNextPaymentRecurringBuy] {
        [.oneTime] + eligibleRecurringBuyFrequenciesAndNextDates
    }

    @BindableState var eligibleRecurringBuyFrequenciesAndNextDates: [EligibleAndNextPaymentRecurringBuy] = []
    @BindableState var recurringBuyFrequency: RecurringBuy.Frequency?
}

// MARK: - Actions

enum RecurringBuyFrequencySelectorAction: Equatable, BindableAction {
    case refresh
    case update(RecurringBuy.Frequency)
    case recurringBuyFrequencySelected(RecurringBuy.Frequency)
    case okTapped
    case closeButtonTapped
    case binding(BindingAction<RecurringBuyFrequencySelectorState>)
}

// MARK: - Reducer

let recurringBuyFrequencySelectorReducer = Reducer<
    RecurringBuyFrequencySelectorState,
    RecurringBuyFrequencySelectorAction,
    RecurringBuyFrequencySelectorEnvironment
> { state, action, environment in
    switch action {
    case .refresh:
        return .merge(
            environment
                .app.publisher(for: blockchain.ux.transaction.checkout.recurring.buy.frequency, as: String.self)
                .receive(on: DispatchQueue.main)
                .compactMap(\.value)
                .compactMap(RecurringBuy.Frequency.init(rawValue:))
                .eraseToEffect()
                .map { .binding(.set(\.$recurringBuyFrequency, $0)) },

            environment
                .app.publisher(for: blockchain.ux.transaction.event.did.fetch.recurring.buy.frequencies, as: [EligibleAndNextPaymentRecurringBuy].self)
                .receive(on: DispatchQueue.main)
                .compactMap(\.value)
                .eraseToEffect()
                .map { .binding(.set(\.$eligibleRecurringBuyFrequenciesAndNextDates, $0)) }
        )

    case .update(let frequency):
        state.recurringBuyFrequency = frequency
        return .none
    case .recurringBuyFrequencySelected(let frequency):
        state.recurringBuyFrequency = frequency
        return .none
    case .binding:
        return .none
    case .okTapped:
        guard let frequency = state.recurringBuyFrequency else { return .none }
        environment.app.state.transaction { appState in
            appState.set(blockchain.ux.transaction.action.select.recurring.buy.frequency, to: frequency.rawValue)
        }
        environment.app.post(event: blockchain.ux.transaction.checkout.recurring.buy.frequency)
        return .fireAndForget {
            environment.dismiss?()
        }
    case .closeButtonTapped:
        return .fireAndForget {
            environment.dismiss?()
        }
    }
}
.binding()

extension RecurringBuy.Frequency {
    typealias LocalizationId = LocalizationConstants.Transaction.Buy.Recurring
    var description: String {
        switch self {
        case .unknown:
            return LocalizationConstants.unknown
        case .once:
            return LocalizationId.oneTimeBuy
        case .daily:
            return LocalizationId.daily
        case .weekly:
            return LocalizationId.weekly
        case .biweekly:
            return LocalizationId.twiceAMonth
        case .monthly:
            return LocalizationId.monthly
        }
    }
}

extension EligibleAndNextPaymentRecurringBuy {
    typealias LocalizationId = LocalizationConstants.Transaction.Buy.Recurring

    var date: String? {
        switch frequency {
        case .unknown,
                .once,
                .daily:
            return nil
        case .weekly:
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return LocalizationId.on + " \(formatter.string(from: nextPaymentDate))"
        case .monthly:
            let formatter = DateFormatter()
            formatter.dateFormat = "d"
            let day = formatter.string(from: nextPaymentDate)
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .ordinal
            guard let next = numberFormatter.string(from: NSNumber(value: Int(day) ?? 0)) else { return nil }
            return LocalizationId.onThe + " " + next
        case .biweekly:
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return LocalizationId.everyOther + " \(formatter.string(from: nextPaymentDate))"
        }
    }
}
