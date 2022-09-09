// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "FeatureOnboarding",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .watchOS(.v7),
        .tvOS(.v14)
    ],
    products: [
        .library(
            name: "FeatureOnboarding",
            targets: ["FeatureOnboardingUI"]
        ),
        .library(
            name: "FeatureOnboardingUI",
            targets: ["FeatureOnboardingUI"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            exact: "0.39.1"
        ),
        .package(
            url: "https://github.com/dchatzieleftheriou-bc/DIKit.git",
            branch: "safe-property-wrappers-locks"
        ),
        .package(path: "../Analytics"),
        .package(path: "../BlockchainComponentLibrary"),
        .package(path: "../ComposableArchitectureExtensions"),
        .package(path: "../Localization"),
        .package(path: "../Test"),
        .package(path: "../Errors"),
        .package(path: "../Tool"),
        .package(path: "../UIComponents")
    ],
    targets: [
        .target(
            name: "FeatureOnboardingUI",
            dependencies: [
                .product(name: "AnalyticsKit", package: "Analytics"),
                .product(name: "BlockchainComponentLibrary", package: "BlockchainComponentLibrary"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ComposableNavigation", package: "ComposableArchitectureExtensions"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "Localization", package: "Localization"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "Errors", package: "Errors"),
                .product(name: "UIComponents", package: "UIComponents")
            ]
        ),
        .testTarget(
            name: "FeatureOnboardingUITests",
            dependencies: [
                .target(name: "FeatureOnboardingUI"),
                .product(name: "AnalyticsKitMock", package: "Analytics"),
                .product(name: "TestKit", package: "Test"),
                .product(name: "ToolKitMock", package: "Tool")
            ]
        )
    ]
)
