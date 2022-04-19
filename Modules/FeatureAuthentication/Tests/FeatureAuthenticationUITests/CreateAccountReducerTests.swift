// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import AnalyticsKitMock
import ComposableArchitecture
@testable import FeatureAuthenticationDomain
import FeatureAuthenticationMock
@testable import FeatureAuthenticationUI
import ToolKitMock
import UIComponentsKit
import XCTest

final class CreateAccountReducerTests: XCTestCase {

    private var testStore: TestStore<
        CreateAccountState,
        CreateAccountState,
        CreateAccountAction,
        CreateAccountAction,
        CreateAccountEnvironment
    >!
    private let mainScheduler: TestSchedulerOf<DispatchQueue> = DispatchQueue.test

    override func setUpWithError() throws {
        try super.setUpWithError()
        testStore = TestStore(
            initialState: CreateAccountState(context: .createWallet),
            reducer: createAccountReducer,
            environment: CreateAccountEnvironment(
                mainQueue: mainScheduler.eraseToAnyScheduler(),
                passwordValidator: PasswordValidator(),
                externalAppOpener: MockExternalAppOpener(),
                analyticsRecorder: MockAnalyticsRecorder(),
                walletRecoveryService: .mock(),
                walletCreationService: .mock(),
                walletFetcherService: .mock
            )
        )
    }

    override func tearDownWithError() throws {
        testStore = nil
        try super.tearDownWithError()
    }

    func test_tapping_next_validates_input_invalidEmail() throws {
        // GIVEN: The form is invalid
        // no-op as form starts emapty
        // WHEN: The user taps on the Next button in either part of the UI
        testStore.send(.createButtonTapped) {
            $0.validatingInput = true
        }
        // THEN: The form is validated
        mainScheduler.advance() // let the validation complete
        // AND: The state is updated
        testStore.receive(.didUpdateInputValidation(.invalid(.invalidEmail))) {
            $0.validatingInput = false
            $0.inputValidationState = .invalid(.invalidEmail)
        }
        testStore.receive(.didValidateAfterFormSubmission)
    }

    func test_tapping_next_validates_input_invalidPassword() throws {
        // GIVEN: The form is invalid
        fillFormEmailField()
        // WHEN: The user taps on the Next button in either part of the UI
        testStore.send(.createButtonTapped) {
            $0.validatingInput = true
        }
        // THEN: The form is validated
        mainScheduler.advance() // let the validation complete
        // AND: The state is updated
        testStore.receive(.didUpdateInputValidation(.invalid(.weakPassword))) {
            $0.validatingInput = false
            $0.inputValidationState = .invalid(.weakPassword)
        }
        testStore.receive(.didValidateAfterFormSubmission)
    }

    func test_tapping_next_validates_input_invalidCountry() throws {
        // GIVEN: The form is invalid
        fillFormEmailField()
        fillFormPasswordField()
        // WHEN: The user taps on the Next button in either part of the UI
        testStore.send(.createButtonTapped) {
            $0.validatingInput = true
        }
        // THEN: The form is validated
        mainScheduler.advance() // let the validation complete
        // AND: The state is updated
        testStore.receive(.didUpdateInputValidation(.invalid(.noCountrySelected))) {
            $0.validatingInput = false
            $0.inputValidationState = .invalid(.noCountrySelected)
        }
        testStore.receive(.didValidateAfterFormSubmission)
    }

    func test_tapping_next_validates_input_invalidState() throws {
        // GIVEN: The form is invalid
        fillFormEmailField()
        fillFormPasswordField()
        fillFormCountryField()
        // WHEN: The user taps on the Next button in either part of the UI
        testStore.send(.createButtonTapped) {
            $0.validatingInput = true
        }
        // THEN: The form is validated
        mainScheduler.advance() // let the validation complete
        // AND: The state is updated
        testStore.receive(.didUpdateInputValidation(.invalid(.noCountryStateSelected))) {
            $0.validatingInput = false
            $0.inputValidationState = .invalid(.noCountryStateSelected)
        }
        testStore.receive(.didValidateAfterFormSubmission)
    }

    func test_tapping_next_validates_input_termsNotAccepted() throws {
        // GIVEN: The form is invalid
        fillFormEmailField()
        fillFormPasswordField()
        fillFormCountryField()
        fillFormCountryStateField()
        // WHEN: The user taps on the Next button in either part of the UI
        testStore.send(.createButtonTapped) {
            $0.validatingInput = true
        }
        // THEN: The form is validated
        mainScheduler.advance() // let the validation complete
        // AND: The state is updated
        testStore.receive(.didUpdateInputValidation(.invalid(.termsNotAccepted))) {
            $0.validatingInput = false
            $0.inputValidationState = .invalid(.termsNotAccepted)
        }
        testStore.receive(.didValidateAfterFormSubmission)
    }

    func test_tapping_next_creates_an_account_when_valid_form() throws {
        // GIVEN: The form is valid
        fillFormWithValidData()
        // WHEN: The user taps on the Next button in either part of the UI
        testStore.send(.createButtonTapped) {
            $0.validatingInput = true
        }
        // THEN: The form is validated
        mainScheduler.advance() // let the validation complete
        // AND: The state is updated
        testStore.receive(.didUpdateInputValidation(.valid)) {
            $0.validatingInput = false
            $0.inputValidationState = .valid
        }
        testStore.receive(.didValidateAfterFormSubmission)
        // AND: The form submission creates an account
        testStore.receive(.createOrImportWallet(.createWallet))
        testStore.receive(.createAccount) {
            $0.isCreatingWallet = true
        }
        testStore.receive(.triggerAuthenticate)
        testStore.receive(.accountCreation(.failure(.creationFailure(.genericFailure)))) {
            $0.isCreatingWallet = false
        }
        testStore.receive(
            .alert(
                .show(
                    title: "Error",
                    message: "creationFailure(WalletPayloadKit.WalletCreateError.genericFailure)"
                )
            )
        ) {
            $0.failureAlert = AlertState(
                title: TextState("Error"),
                message: TextState("creationFailure(WalletPayloadKit.WalletCreateError.genericFailure)"),
                dismissButton: AlertState.Button.default(
                    TextState("OK"),
                    action: AlertState.ButtonAction.send(
                        CreateAccountAction.alert(CreateAccountAction.AlertAction.dismiss)
                    )
                )
            )
        }
    }

    // MARK: - Helpers

    private func fillFormWithValidData() {
        fillFormEmailField()
        fillFormPasswordField()
        fillFormCountryField()
        fillFormCountryStateField()
        fillFormAcceptanceOfTermsAndConditions()
    }

    private func fillFormEmailField(email: String = "test@example.com") {
        testStore.send(.binding(.set(\.$emailAddress, email))) {
            $0.emailAddress = email
        }
        testStore.receive(.didUpdateInputValidation(.unknown))
    }

    private func fillFormPasswordField(
        password: String = "MyPass124)",
        expectedScore: PasswordValidationScore = .normal
    ) {
        testStore.send(.binding(.set(\.$password, password))) {
            $0.password = password
        }
        testStore.receive(.didUpdateInputValidation(.unknown))
        testStore.receive(.validatePasswordStrength)
        mainScheduler.advance()
        testStore.receive(.didUpdatePasswordStrenght(expectedScore)) {
            $0.passwordStrength = expectedScore
        }
    }

    private func fillFormCountryField(country: SearchableItem<String> = .init(id: "US", title: "United States")) {
        testStore.send(.binding(.set(\.$country, country))) {
            $0.country = country
        }
        testStore.receive(.didUpdateInputValidation(.unknown))
        testStore.receive(.binding(.set(\.$selectedAddressSegmentPicker, nil)))
        testStore.receive(.route(nil))
    }

    private func fillFormCountryStateField(state: SearchableItem<String> = SearchableItem(id: "FL", title: "Florida")) {
        testStore.send(.binding(.set(\.$countryState, state))) {
            $0.countryState = state
        }
        testStore.receive(.didUpdateInputValidation(.unknown))
        testStore.receive(.binding(.set(\.$selectedAddressSegmentPicker, nil)))
        testStore.receive(.route(nil))
    }

    private func fillFormAcceptanceOfTermsAndConditions(termsAccepted: Bool = true) {
        testStore.send(.binding(.set(\.$termsAccepted, termsAccepted))) {
            $0.termsAccepted = termsAccepted
        }
        testStore.receive(.didUpdateInputValidation(.unknown))
    }
}
