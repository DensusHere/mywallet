import SwiftUI

struct ImageAsset {
    enum Deletion {
        static var deletionFailed: Image {
            Image(
                "deletion-failed",
                bundle: .FeatureUserDeletion
            )
        }

        static var deletionSuceeded: Image {
            Image(
                "deletion-suceeded",
                bundle: .FeatureUserDeletion
            )
        }
    }
}

// MARK: Helper function

private class BundleFinder {}

extension Bundle {
    static let FeatureUserDeletion = Bundle.find(
        "FeatureUserDeletion_FeatureUserDeletionUI.bundle",
        in: BundleFinder.self
    )
}
