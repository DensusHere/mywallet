// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FeatureCryptoDomain",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "FeatureCryptoDomain",
            targets: ["FeatureCryptoDomainData", "FeatureCryptoDomainDomain", "FeatureCryptoDomainUI"]
        ),
        .library(
            name: "FeatureCryptoDomainUI",
            targets: ["FeatureCryptoDomainUI"]
        ),
        .library(
            name: "FeatureCryptoDomainDomain",
            targets: ["FeatureCryptoDomainDomain"]
        ),
        .library(
            name: "FeatureCryptoDomainMock",
            targets: ["FeatureCryptoDomainMock"]
        )
    ],
    dependencies: [
        .package(
            name: "swift-composable-architecture",
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "0.18.0"
        ),
        .package(
            name: "DIKit",
            url: "https://github.com/jackpooleybc/DIKit.git",
            .branch("safe-property-wrappers")
        ),
        .package(path: "../Analytics"),
        .package(path: "../BlockchainComponentLibrary"),
        .package(path: "../ComposableArchitectureExtensions"),
        .package(path: "../Localization"),
        .package(path: "../Network"),
        .package(path: "../NetworkErrors"),
        .package(path: "../Test"),
        .package(path: "../Tool")
    ],
    targets: [
        .target(
            name: "FeatureCryptoDomainDomain",
            dependencies: [
                .product(name: "Localization", package: "Localization"),
                .product(name: "NetworkError", package: "NetworkErrors"),
                .product(name: "ToolKit", package: "Tool")
            ]
        ),
        .target(
            name: "FeatureCryptoDomainData",
            dependencies: [
                .target(name: "FeatureCryptoDomainDomain"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "NetworkKit", package: "Network"),
                .product(name: "NetworkError", package: "NetworkErrors")
            ]
        ),
        .target(
            name: "FeatureCryptoDomainUI",
            dependencies: [
                .target(name: "FeatureCryptoDomainDomain"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "ComposableNavigation", package: "ComposableArchitectureExtensions"),
                .product(name: "AnalyticsKit", package: "Analytics"),
                .product(name: "Localization", package: "Localization"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "BlockchainComponentLibrary", package: "BlockchainComponentLibrary")
            ]
        ),
        .target(
            name: "FeatureCryptoDomainMock",
            dependencies: [
                .target(name: "FeatureCryptoDomainData"),
                .target(name: "FeatureCryptoDomainDomain")
            ]
        ),
        .testTarget(
            name: "FeatureCryptoDomainDataTests",
            dependencies: [
                .target(name: "FeatureCryptoDomainData"),
                .target(name: "FeatureCryptoDomainMock"),
                .product(name: "TestKit", package: "Test")
            ]
        ),
        .testTarget(
            name: "FeatureCryptoDomainUITests",
            dependencies: [
                .target(name: "FeatureCryptoDomainData"),
                .target(name: "FeatureCryptoDomainUI"),
                .target(name: "FeatureCryptoDomainMock"),
                .product(name: "AnalyticsKitMock", package: "Analytics"),
                .product(name: "TestKit", package: "Test"),
                .product(name: "ToolKitMock", package: "Tool")
            ]
        )
    ]
)
