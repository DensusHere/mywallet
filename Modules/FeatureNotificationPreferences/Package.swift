// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FeatureNotificationPreferences",
    defaultLocalization: "en",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(name: "FeatureNotificationPreferences", targets: [
            "FeatureNotificationPreferencesDomain",
            "FeatureNotificationPreferencesUI",
            "FeatureNotificationPreferencesData"
        ]),
        .library(name: "FeatureNotificationPreferencesDetails", targets: ["FeatureNotificationPreferencesDetailsUI"]),
        .library(name: "FeatureNotificationPreferencesMocks", targets: ["FeatureNotificationPreferencesMocks"]),
        .library(name: "FeatureNotificationPreferencesDomain", targets: ["FeatureNotificationPreferencesDomain"]),
        .library(name: "FeatureNotificationPreferencesUI", targets: ["FeatureNotificationPreferencesUI"]),
        .library(name: "FeatureNotificationPreferencesData", targets: ["FeatureNotificationPreferencesData"]),
        .library(name: "FeatureNotificationPreferencesDetailsUI", targets: ["FeatureNotificationPreferencesDetailsUI"])
    ],
    dependencies: [
        .package(
            name: "swift-composable-architecture",
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "0.34.0"
        ),
        .package(
            name: "SnapshotTesting",
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.9.0"
        ),
        .package(path: "../Analytics"),
        .package(path: "../BlockchainComponentLibrary"),
        .package(path: "../ComposableArchitectureExtensions"),
        .package(path: "../Localization"),
        .package(path: "../Network"),
        .package(path: "../NetworkErrors"),
        .package(path: "../Tool"),
        .package(path: "../UIComponents"),
        .package(path: "../Test")
    ],
    targets: [
        .target(
            name: "FeatureNotificationPreferencesDomain",
            dependencies: [
                .product(
                    name: "NetworkError",
                    package: "NetworkErrors"
                ),
                .product(
                    name: "Localization",
                    package: "Localization"
                ),
                .product(
                    name: "NetworkError",
                    package: "NetworkErrors"
                ),
                .product(name: "NabuNetworkError", package: "NetworkErrors"),
                .product(
                    name: "BlockchainComponentLibrary",
                    package: "BlockchainComponentLibrary"
                )
            ],
            path: "Sources/NotificationPreferences/NotificationPreferencesDomain"
        ),
        .target(
            name: "FeatureNotificationPreferencesData",
            dependencies: [
                .target(
                    name: "FeatureNotificationPreferencesDomain"
                ),
                .product(
                    name: "NetworkKit",
                    package: "Network"
                ),
                .product(
                    name: "NetworkError",
                    package: "NetworkErrors"
                )
            ],
            path: "Sources/NotificationPreferences/NotificationPreferencesData"
        ),
        .target(
            name: "FeatureNotificationPreferencesUI",
            dependencies: [
                .target(name: "FeatureNotificationPreferencesDomain"),
                .target(name: "FeatureNotificationPreferencesDetailsUI"),
                .target(name: "FeatureNotificationPreferencesMocks"),
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
                .product(
                    name: "BlockchainComponentLibrary",
                    package: "BlockchainComponentLibrary"
                ),
                .product(
                    name: "AnalyticsKit",
                    package: "Analytics"
                ),
                .product(
                    name: "Localization",
                    package: "Localization"
                ),
                .product(
                    name: "ToolKit",
                    package: "Tool"
                ),
                .product(
                    name: "NetworkError",
                    package: "NetworkErrors"
                ),
                .product(name: "UIComponents", package: "UIComponents"),
                .product(
                    name: "ComposableArchitectureExtensions",
                    package: "ComposableArchitectureExtensions"
                )
            ],
            path: "Sources/NotificationPreferences/NotificationPreferencesUI"
        ),
        .target(
            name: "FeatureNotificationPreferencesDetailsUI",
            dependencies: [
                .target(
                    name: "FeatureNotificationPreferencesDomain"
                ),
                .target(name: "FeatureNotificationPreferencesMocks"),
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
                .product(
                    name: "BlockchainComponentLibrary",
                    package: "BlockchainComponentLibrary"
                ),
                .product(
                    name: "AnalyticsKit",
                    package: "Analytics"
                ),
                .product(
                    name: "Localization",
                    package: "Localization"
                ),
                .product(
                    name: "ToolKit",
                    package: "Tool"
                ),
                .product(
                    name: "NetworkError",
                    package: "NetworkErrors"
                ),
                .product(
                    name: "ComposableArchitectureExtensions",
                    package: "ComposableArchitectureExtensions"
                )
            ],
            path: "Sources/NotificationPreferencesDetails/NotificationPreferencesDetailsUI"
        ),
        .target(
            name: "FeatureNotificationPreferencesMocks",
            dependencies: [
                .target(name: "FeatureNotificationPreferencesDomain")
            ],
            path: "Sources/FeatureNotificationPreferencesMocks"
        ),
        .testTarget(
            name: "FeatureNotificationPreferencesUITests",
            dependencies: [
                .target(name: "FeatureNotificationPreferencesUI"),
                .target(name: "FeatureNotificationPreferencesData"),
                .target(name: "FeatureNotificationPreferencesDomain"),
                .target(name: "FeatureNotificationPreferencesMocks"),
                .product(name: "AnalyticsKitMock", package: "Analytics"),
                .product(name: "SnapshotTesting", package: "SnapshotTesting"),
                .product(name: "TestKit", package: "Test")
            ],
            exclude: ["__Snapshots__"]
        )
    ]
)
