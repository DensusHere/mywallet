// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "UIComponents",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .watchOS(.v7),
        .tvOS(.v14)
    ],
    products: [
        .library(
            name: "UIComponents",
            targets: ["UIComponentsKit"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.9.0"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-case-paths",
            from: "0.9.1"
        ),
        .package(path: "../Tool"),
        .package(path: "../BlockchainComponentLibrary")
    ],
    targets: [
        .target(
            name: "UIComponentsKit",
            dependencies: [
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "BlockchainComponentLibrary", package: "BlockchainComponentLibrary")
            ],
            path: "UIComponentsKit"
        ),
        .testTarget(
            name: "UIComponentsKitTests",
            dependencies: [
                "UIComponentsKit",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            path: "UIComponentsKitTests",
            exclude: ["__Snapshots__"]
        )
    ]
)
