// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "FeatureCoin",
    defaultLocalization: "en",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(name: "FeatureCoin", targets: [
            "FeatureCoinDomain",
            "FeatureCoinUI",
            "FeatureCoinData"
        ]),
        .library(name: "FeatureCoinDomain", targets: ["FeatureCoinDomain"]),
        .library(name: "FeatureCoinUI", targets: ["FeatureCoinUI"]),
        .library(name: "FeatureCoinData", targets: ["FeatureCoinData"])
    ],
    dependencies: [
        .package(
            name: "swift-composable-architecture",
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "0.32.0"
        ),
        .package(path: "../BlockchainComponentLibrary"),
        .package(path: "../Localization"),
        .package(path: "../Tool"),
        .package(path: "../Money"),
        .package(path: "../Network"),
        .package(path: "../NetworkErrors")
    ],
    targets: [
        .target(
            name: "FeatureCoinDomain",
            dependencies: [
                .product(
                    name: "MoneyKit",
                    package: "Money"
                )
            ]
        ),
        .target(
            name: "FeatureCoinData",
            dependencies: [
                .target(name: "FeatureCoinDomain"),
                .product(name: "NetworkKit", package: "Network")
            ]
        ),
        .target(
            name: "FeatureCoinUI",
            dependencies: [
                .target(name: "FeatureCoinDomain"),
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
                .product(
                    name: "BlockchainComponentLibrary",
                    package: "BlockchainComponentLibrary"
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
                    name: "MoneyKit",
                    package: "Money"
                ),
                .product(
                    name: "NetworkError",
                    package: "NetworkErrors"
                )
            ]
        ),
        .testTarget(
            name: "FeatureCoinDomainTests",
            dependencies: [
            ]
        ),
        .testTarget(
            name: "FeatureCoinDataTests",
            dependencies: [
            ]
        ),
        .testTarget(
            name: "FeatureCoinUITests",
            dependencies: [
            ]
        )
    ]
)
