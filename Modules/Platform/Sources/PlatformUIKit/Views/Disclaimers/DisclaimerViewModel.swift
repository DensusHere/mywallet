// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation

public class DisclaimerViewModel {

    public var textSubject: CurrentValueSubject<NSAttributedString?, Never>
    public var text: AnyPublisher<NSAttributedString?, Never> {
        textSubject.eraseToAnyPublisher()
    }

    public init(text: NSAttributedString?) {
        textSubject = .init(text)
    }
}
