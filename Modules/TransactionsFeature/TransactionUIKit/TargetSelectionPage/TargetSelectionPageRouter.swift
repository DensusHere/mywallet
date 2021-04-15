//
//  TargetSelectionPageRouter.swift
//  TransactionUIKit
//
//  Created by Dimitrios Chatzieleftheriou on 01/02/2021.
//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.
//

import PlatformKit
import PlatformUIKit
import RIBs
import TransactionKit

protocol TargetSelectionPageInteractable: Interactable {
    var router: TargetSelectionPageRouting? { get set }
    var listener: TargetSelectionPageListener? { get set }
}

final class TargetSelectionPageRouter: ViewableRouter<TargetSelectionPageInteractable, TargetSelectionPageViewControllable>,
                                       TargetSelectionPageRouting {

    override init(interactor: TargetSelectionPageInteractable, viewController: TargetSelectionPageViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    func presentQRScanner(for currency: CryptoCurrency,
                          sourceAccount: CryptoAccount,
                          model: TargetSelectionPageModel) {
        let parser = CryptoTargetQRCodeParser(assetType: currency)
        let textViewModel = TargetSelectionQRScanningViewModel()
        let builder = QRCodeScannerViewControllerBuilder(
            parser: parser,
            textViewModel: textViewModel,
            completed: { result in
                model.process(action: .returnToPreviousStep)
                if case .success(let value) = result {
                    switch value {
                    case .metadata(let metadata):
                        /// We need to validate the address as if it were a
                        /// value provided by user entry in the text field.
                        model.process(action: .validateQRScanner(metadata.address))
                    case .bitpay(let value):
                        model.process(action: .validateBitPayPayload(value, currency))
                    }
                }
            },
            closeHandler: {
                model.process(action: .returnToPreviousStep)
            }
        )
        
        guard let viewController = builder.build() else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.viewController.uiviewController.present(viewController, animated: true, completion: nil)
        }
    }
}
