// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import PlatformKit
import RxCocoa
import RxRelay
import RxSwift
import ToolKit
import UIComponentsKit
import UIKit

public final class AmountTranslationView: UIView, AmountViewable {

    public var view: UIView {
        self
    }

    // MARK: - Types

    private struct AmountLabelConstraints {
        var top: [NSLayoutConstraint]
        var bottom: [NSLayoutConstraint]

        init(top: [NSLayoutConstraint], bottom: [NSLayoutConstraint]) {
            self.top = top
            self.bottom = bottom
        }

        func activate() {
            top.forEach { $0.priority = .penultimateHigh }
            bottom.forEach { $0.priority = .penultimateLow }
        }

        func deactivate() {
            top.forEach { $0.priority = .penultimateLow }
            bottom.forEach { $0.priority = .penultimateHigh }
        }
    }

    // MARK: - Properties

    private let fiatAmountLabelView = AmountLabelView()
    private let cryptoAmountLabelView = AmountLabelView()
    private let auxiliaryButton = ButtonView()
    private let swapButton: UIButton = {
        var swapButton = UIButton()
        swapButton.layer.borderWidth = 1
        swapButton.layer.cornerRadius = 8
        swapButton.layer.borderColor = UIColor.mediumBorder.cgColor
        swapButton.setImage(UIImage(named: "vertical-swap-icon", in: .platformUIKit, with: nil), for: .normal)
        return swapButton
    }()

    private let presenter: AmountTranslationPresenter
    private let labelsStackView: UIStackView

    private let disposeBag = DisposeBag()

    // MARK: - Init

    @available(*, unavailable)
    public required init?(coder: NSCoder) { unimplemented() }

    public init(presenter: AmountTranslationPresenter) {
        self.presenter = presenter
        labelsStackView = UIStackView(arrangedSubviews: [fiatAmountLabelView, cryptoAmountLabelView])
        labelsStackView.axis = .vertical
        super.init(frame: UIScreen.main.bounds)

        fiatAmountLabelView.presenter = presenter.fiatPresenter.presenter
        cryptoAmountLabelView.presenter = presenter.cryptoPresenter.presenter

        swapButton.layout(size: .init(edge: 40))
        // a view to offset the swap button on the leading size, so that the inner stack view looks centered.
        let offsetView = UIView()
        offsetView.layout(size: .init(edge: 40))

        let innerStackView = UIStackView(arrangedSubviews: [offsetView, labelsStackView, swapButton])
        innerStackView.axis = .horizontal
        innerStackView.alignment = .center
        innerStackView.spacing = Spacing.standard

        let contentStackView = UIStackView(arrangedSubviews: [innerStackView, auxiliaryButton])
        contentStackView.axis = .vertical
        contentStackView.alignment = .center
        contentStackView.spacing = Spacing.standard

        innerStackView.constraint(axis: .horizontal, to: contentStackView)

        // used to center the content
        let outerStackView = UIStackView(arrangedSubviews: [contentStackView])
        outerStackView.axis = .horizontal
        outerStackView.alignment = .center

        addSubview(outerStackView)
        outerStackView.constraint(
            edgesTo: self,
            insets: UIEdgeInsets(horizontal: Spacing.outer, vertical: Spacing.standard)
        )

        labelsStackView.maximizeResistanceAndHuggingPriorities()

        auxiliaryButton.layoutToSuperview(.leading, relation: .greaterThanOrEqual)
        auxiliaryButton.layoutToSuperview(.trailing, relation: .lessThanOrEqual)

        presenter.swapButtonVisibility
            .drive(swapButton.rx.visibility)
            .disposed(by: disposeBag)

        swapButton.rx.tap
            .bindAndCatch(to: presenter.swapButtonTapRelay)
            .disposed(by: disposeBag)

        presenter.activeAmountInput
            .map { input -> Bool in
                input == .fiat
            }
            .drive(fiatAmountLabelView.presenter.focusRelay)
            .disposed(by: disposeBag)

        presenter.activeAmountInput
            .map { input -> Bool in
                input == .crypto
            }
            .drive(cryptoAmountLabelView.presenter.focusRelay)
            .disposed(by: disposeBag)

        presenter.activeAmountInput
            .drive(
                onNext: { [weak self] input in
                    self?.didChangeActiveInput(to: input)
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Public Methods

    public func connect(input: Driver<AmountPresenterInput>) -> Driver<AmountPresenterState> {
        Driver.combineLatest(
            presenter.connect(input: input),
            presenter.activeAmountInput,
            presenter.auxiliaryButtonEnabled
        )
        .map { (state: $0.0, activeAmountInput: $0.1, auxiliaryEnabled: $0.2) }
        .map { [weak self] value in
            guard let self = self else { return .validInput(nil) }
            return self.performEffect(
                state: value.state,
                activeAmountInput: value.activeAmountInput,
                auxiliaryButtonEnabled: value.auxiliaryEnabled
            )
        }
    }

    // MARK: - Private Methods

    private func performEffect(
        state: AmountPresenterState,
        activeAmountInput: ActiveAmountInput,
        auxiliaryButtonEnabled: Bool
    ) -> AmountPresenterState {
        let textColor: UIColor
        switch state {
        case .validInput(let viewModel):
            textColor = .validInput
            auxiliaryButton.viewModel = viewModel
        case .invalidInput(let viewModel):
            textColor = .invalidInput
            auxiliaryButton.viewModel = viewModel
        }

        let shouldShowAuxiliaryButton = auxiliaryButtonEnabled && auxiliaryButton.viewModel != nil
        auxiliaryButton.isHidden = !shouldShowAuxiliaryButton
        fiatAmountLabelView.textColor = textColor
        cryptoAmountLabelView.textColor = textColor

        return state
    }

    private func didChangeActiveInput(to newInput: ActiveAmountInput) {
        layoutIfNeeded()
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0,
            options: [.beginFromCurrentState, .curveEaseInOut],
            animations: {
                switch newInput {
                case .fiat:
                    // remove bottom label from current position and add it back as last view in the stack
                    self.labelsStackView.removeArrangedSubview(self.cryptoAmountLabelView)
                    self.labelsStackView.addArrangedSubview(self.cryptoAmountLabelView)
                    // ensure that the selected crypto can be compressed to make room for the other input on small screens
                    self.fiatAmountLabelView.verticalContentCompressionResistancePriority = .defaultHigh
                    self.cryptoAmountLabelView.verticalContentCompressionResistancePriority = .required
                case .crypto:
                    // remove bottom label from current position and add it back as last view in the stack
                    self.labelsStackView.removeArrangedSubview(self.fiatAmountLabelView)
                    self.labelsStackView.addArrangedSubview(self.fiatAmountLabelView)
                    // ensure that the selected crypto can be compressed to make room for the other input on small screens
                    self.fiatAmountLabelView.verticalContentCompressionResistancePriority = .required
                    self.cryptoAmountLabelView.verticalContentCompressionResistancePriority = .defaultHigh
                }
                self.layoutIfNeeded()
            },
            completion: nil
        )
    }
}