// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import BlockchainComponentLibrary
import SnapshotTesting
import XCTest

final class PrimarySwitchTests: XCTestCase {

    override func setUp() {
        super.setUp()
        isRecording = false
    }

    func testPrimarySwitch() {
        let view = PrimarySwitch_Previews.previews

        assertSnapshot(matching: view, as: .image)
    }
}
