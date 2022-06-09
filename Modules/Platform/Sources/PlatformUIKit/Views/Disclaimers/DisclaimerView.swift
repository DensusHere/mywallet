// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Foundation
import UIKit

public final class DisclaimerView: UIView {

    // MARK: - UI Properties

    private let textView = UITextView(frame: .zero)
    private var shimmeringView: ShimmeringView?

    // MARK: - Rx

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies

    public var viewModel: DisclaimerViewModel! {
        willSet {
            cancellables.removeAll()
        }
        didSet {
            guard let viewModel = viewModel else {
                return
            }
            viewModel.text
                .map { text -> NSAttributedString? in
                    guard let text = text else { return nil }
                    let disclaimerText = NSMutableAttributedString(attributedString: text)
                    disclaimerText.addAttributes(
                        [
                            .font: UIFont.main(.medium, 12),
                            .foregroundColor: UIColor.descriptionText
                        ],
                        range: NSRange(location: 0, length: disclaimerText.length)
                    )
                    return disclaimerText
                }
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] text in
                    self?.textView.attributedText = text
                    self?.textView.sizeToFit()
                    text == nil
                        ? self?.shimmeringView?.start()
                        : self?.shimmeringView?.stop()
                })
                .store(in: &cancellables)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        addSubview(textView)
        textView.textAlignment = .center
        textView.isScrollEnabled = false
        textView.accessibility = .id("disclaimer")
        textView.isSelectable = true
        textView.layout(edges: .bottom, .top, .leading, .trailing, to: self)

        shimmeringView = ShimmeringView(
            in: self,
            anchorView: textView,
            size: .init(width: 360, height: 12)
        )
    }
}
