#if canImport(UIKit)
import BlockchainComponentLibrary
import BlockchainNamespace
import ErrorsUI
import SnapshotTesting
import SwiftUI
import XCTest

final class ErrorViewSnapshotTests: XCTestCase {

    let error = UX.Error(
        source: nil,
        title: "Oops! Something went wrong!",
        message: "Don’t worry. Your crypto is safe. Please try again or contact our Support Team for help.",
        icon: nil,
        metadata: [
            "ID": "error-id"
        ],
        actions: .default
    )

    override static func setUp() {
        super.setUp()
        isRecording = false
    }

    func test() {

        let view = PrimaryNavigationView {
            ErrorView(
                ux: error,
                dismiss: {}
            )
        }
        .app(App.test)

        assertSnapshots(
            matching: view,
            as: [
                .image(
                    layout: .device(config: .iPhone8),
                    traits: .init(userInterfaceStyle: .light)
                ),
                .image(
                    layout: .device(config: .iPhone8),
                    traits: .init(userInterfaceStyle: .dark)
                ),
                .image(
                    layout: .device(config: .iPhoneSe),
                    traits: .init(userInterfaceStyle: .light)
                ),
                .image(
                    layout: .device(config: .iPhoneXsMax),
                    traits: .init(userInterfaceStyle: .light)
                )
            ]
        )
    }
}
#endif
