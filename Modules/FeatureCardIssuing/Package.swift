// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FeatureCardIssuing",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "FeatureCardIssuing",
            targets: ["FeatureCardIssuingData", "FeatureCardIssuingDomain", "FeatureCardIssuingUI"]
        ),
        .library(
            name: "FeatureCardIssuingUI",
            targets: ["FeatureCardIssuingUI"]
        ),
        .library(
            name: "FeatureCardIssuingDomain",
            targets: ["FeatureCardIssuingDomain"]
        )
    ],
    dependencies: [
        .package(
            name: "DIKit",
            url: "https://github.com/jackpooleybc/DIKit.git",
            .branch("safe-property-wrappers")
        ),
        .package(
            name: "swift-composable-architecture",
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "0.34.0"
        ),
        .package(path: "../Analytics"),
        .package(path: "../ComposableArchitectureExtensions"),
        .package(path: "../Localization"),
        .package(path: "../Network"),
        .package(path: "../NetworkErrors"),
        .package(path: "../Tool"),
        .package(path: "../Money"),
        .package(path: "../BlockchainComponentLibrary")
    ],
    targets: [
        .target(
            name: "FeatureCardIssuingDomain",
            dependencies: [
                .product(name: "NabuNetworkError", package: "NetworkErrors"),
                .product(name: "NetworkError", package: "NetworkErrors"),
                .product(name: "NetworkKit", package: "Network"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "MoneyKit", package: "Money")
            ]
        ),
        .target(
            name: "FeatureCardIssuingData",
            dependencies: [
                .target(name: "FeatureCardIssuingDomain"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "NetworkKit", package: "Network"),
                .product(name: "NetworkError", package: "NetworkErrors"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "MoneyKit", package: "Money")
            ]
        ),
        .target(
            name: "FeatureCardIssuingUI",
            dependencies: [
                .target(name: "FeatureCardIssuingDomain"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "AnalyticsKit", package: "Analytics"),
                .product(name: "Localization", package: "Localization"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "NabuNetworkError", package: "NetworkErrors"),
                .product(name: "BlockchainComponentLibrary", package: "BlockchainComponentLibrary"),
                .product(name: "MoneyKit", package: "Money")
            ]
        )
    ]
)
