// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FeatureOnboarding",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "FeatureOnboarding", targets: ["FeatureOnboardingUI"]),
        .library(name: "FeatureOnboardingUI", targets: ["FeatureOnboardingUI"])
    ],
    dependencies: [
        .package(path: "../Analytics"),
        .package(path: "../BlockchainComponentLibrary"),
        .package(
            name: "swift-composable-architecture",
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "0.34.0"
        ),
        .package(path: "../ComposableArchitectureExtensions"),
        .package(
            name: "DIKit",
            url: "https://github.com/jackpooleybc/DIKit.git",
            .branch("safe-property-wrappers")
        ),
        .package(path: "../Localization"),
        .package(path: "../Platform"),
        .package(path: "../Test"),
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
                .product(name: "UIComponents", package: "UIComponents")
            ]
        ),
        .testTarget(
            name: "FeatureOnboardingUITests",
            dependencies: [
                .target(name: "FeatureOnboardingUI"),
                .product(name: "AnalyticsKitMock", package: "Analytics"),
                .product(name: "PlatformUIKitMock", package: "Platform"),
                .product(name: "TestKit", package: "Test"),
                .product(name: "ToolKitMock", package: "Tool")
            ]
        )
    ]
)
