// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import FeatureAppUpgradeUI
import SnapshotTesting
import SwiftUI
import XCTest

final class AppUpgradeViewSnapshotTests: XCTestCase {

    let record = false

    func testUnsupportedOS() {
        let view = view(state: .unsupportedOS)
        assertSnapshots(
            matching: view,
            as: [
                .image(traits: UITraitCollection(userInterfaceStyle: .light)),
                .image(traits: UITraitCollection(userInterfaceStyle: .dark))
            ],
            record: record
        )
    }

    func testSoftUpgrade() {
        let view = view(state: .softUpgrade)
        assertSnapshots(
            matching: view,
            as: [
                .image(traits: UITraitCollection(userInterfaceStyle: .light)),
                .image(traits: UITraitCollection(userInterfaceStyle: .dark))
            ],
            record: record
        )
    }

    func testHardUpgrade() {
        let view = view(state: .hardUpgrade)
        assertSnapshots(
            matching: view,
            as: [
                .image(traits: UITraitCollection(userInterfaceStyle: .light)),
                .image(traits: UITraitCollection(userInterfaceStyle: .dark))
            ],
            record: record
        )
    }

    func testAppMaintenance() {
        let view = view(state: .appMaintenance)
        assertSnapshots(
            matching: view,
            as: [
                .image(traits: UITraitCollection(userInterfaceStyle: .light)),
                .image(traits: UITraitCollection(userInterfaceStyle: .dark))
            ],
            record: record
        )
    }

    func testMaintenance() {
        let view = view(state: .maintenance)
        assertSnapshots(
            matching: view,
            as: [
                .image(traits: UITraitCollection(userInterfaceStyle: .light)),
                .image(traits: UITraitCollection(userInterfaceStyle: .dark))
            ],
            record: record
        )
    }

    func view(state: AppUpgradeState.Style) -> some View {
        AppUpgradeView(
            store: .init(
                initialState: AppUpgradeState(style: state, url: ""),
                reducer: appUpgradeReducer,
                environment: ()
            )
        )
        .frame(width: 100.vw, height: 600.pt)
    }
}
