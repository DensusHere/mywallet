// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import Errors
import FeatureReferralDomain
import Localization
import NukeExtensions
import PlatformUIKit
import UIComponentsKit
import UIKit

struct ReferralTableViewCellViewModel {
    let referral: Referral
    let accessibilityID = Accessibility.Identifier.Settings.ReferralCell.view

    init(
        referral: Referral
    ) {
        self.referral = referral
    }
}

final class ReferralTableViewCell: UITableViewCell {
    typealias ViewModel = ReferralTableViewCellViewModel

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 16
        layer.masksToBounds = true
    }

    var viewModel: ViewModel! {
        didSet {
            if let announcement = viewModel.referral.announcement {
                configure(announcement)
            } else {
                titleLabel.text = LocalizationConstants.Referrals.SettingsScreen.buttonTitle
                subtitleLabel.text = viewModel.referral.rewardTitle
                backgroundImageView.contentMode = .right
                backgroundImageView.image = UIImage(named: "referral-image", in: .featureSettingsUI, with: nil)
                iconContainer.removeFromSuperview()
            }
            accessibility = .id(viewModel.accessibilityID)
        }
    }

    // MARK: - Private IBOutlets

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var iconContainer: UIView!
    @IBOutlet private var backgroundImageView: UIImageView!

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        guard let viewModel = viewModel, let container = iconContainer else { return }

        for subview in container.subviews {
            subview.removeFromSuperview()
        }

        if let icon = viewModel.referral.announcement?.icon, let viewController = findViewController() {
            let media = UIHostingController(rootView: AsyncMedia(url: icon.url))
            media.view.translatesAutoresizingMaskIntoConstraints = false
            media.view.backgroundColor = .clear
            viewController.addChild(media)
            container.addSubview(media.view)
            container.addConstraints(
                media.view.constraint(edgesTo: container)
            )
            media.didMove(toParent: viewController)
        } else {
            container.removeFromSuperview()
        }
    }

    private func configure(_ announcement: UX.Dialog) {
        titleLabel.text = announcement.title
        subtitleLabel.text = announcement.message
        if let media = announcement.style?.background?.media {
            backgroundImageView.contentMode = .scaleAspectFill
            loadImage(with: media.url, into: backgroundImageView)
        } else if let color = announcement.style?.background?.color {
            backgroundImageView.image = nil
            backgroundColor = UIColor(color.swiftUI)
        } else {
            backgroundImageView.image = UIImage(named: "referral-image", in: .featureSettingsUI, with: nil)
        }
        if let foregroundColor = announcement.style?.foreground?.color {
            titleLabel.textColor = UIColor(foregroundColor.swiftUI)
            subtitleLabel.textColor = UIColor(foregroundColor.swiftUI)
        } else {
            titleLabel.textColor = UIColor(Color.semantic.light)
            subtitleLabel.textColor = UIColor(Color.semantic.light)
        }
    }
}

extension UIView {

    fileprivate func findViewController() -> UIViewController? {
        if let nextResponder = next as? UIViewController {
            return nextResponder
        } else if let nextResponder = next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}
