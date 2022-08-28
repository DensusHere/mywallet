// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "FeatureUserDeletion",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .watchOS(.v7),
        .tvOS(.v14)
    ],
    products: [
        .library(
            name: "FeatureUserDeletionData",
            targets: ["FeatureUserDeletionData"]
        ),
        .library(
            name: "FeatureUserDeletionDomain",
            targets: ["FeatureUserDeletionDomain"]
        ),
        .library(
            name: "FeatureUserDeletionUI",
            targets: ["FeatureUserDeletionUI"]
        ),
        .library(name: "FeatureUserDeletionMock", targets: ["FeatureUserDeletionDomainMock"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            exact: "0.39.1"
        ),
        .package(path: "../Analytics"),
        .package(path: "../BlockchainComponentLibrary"),
        .package(path: "../ComposableArchitectureExtensions"),
        .package(path: "../Errors"),
        .package(path: "../Localization"),
        .package(path: "../Network"),
        .package(path: "../UIComponents"),
        .package(path: "../Platform"),
        .package(path: "../Test")
    ],
    targets: [
        .target(
            name: "FeatureUserDeletionData",
            dependencies: [
                .product(name: "Errors", package: "Errors"),
                .product(name: "NetworkKit", package: "Network"),
                "FeatureUserDeletionDomain"
            ]
        ),
        .target(
            name: "FeatureUserDeletionDomain",
            dependencies: [
                .product(name: "Errors", package: "Errors")
            ]
        ),
        .target(
            name: "FeatureUserDeletionUI",
            dependencies: [
                .product(
                    name: "AnalyticsKit",
                    package: "Analytics"
                ),
                .product(
                    name: "BlockchainComponentLibrary",
                    package: "BlockchainComponentLibrary"
                ),
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
                .product(
                    name: "ComposableArchitectureExtensions",
                    package: "ComposableArchitectureExtensions"
                ),
                .product(
                    name: "Localization",
                    package: "Localization"
                ),
                .product(
                    name: "UIComponents",
                    package: "UIComponents"
                )
            ]
        ),
        .target(
            name: "FeatureUserDeletionDomainMock",
            dependencies: [
                .target(name: "FeatureUserDeletionDomain"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "PlatformUIKit", package: "Platform")
            ]
        ),
        .testTarget(
            name: "FeatureUserDeletionUITests",
            dependencies: [
                .target(name: "FeatureUserDeletionDomain"),
                .target(name: "FeatureUserDeletionUI"),
                .target(name: "FeatureUserDeletionDomainMock"),
                .product(name: "TestKit", package: "Test")
            ],
            exclude: [
                "__Snapshots__"
            ]
        )
    ]
)
