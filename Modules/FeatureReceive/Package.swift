// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "FeatureReceive",
    platforms: [
        .iOS(.v15),
        .macOS(.v13),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "FeatureReceive",
            targets: ["FeatureReceiveDomain", "FeatureReceiveUI"]
        ),
        .library(
            name: "FeatureReceiveDomain",
            targets: ["FeatureReceiveDomain"]
        ),
        .library(
            name: "FeatureReceiveUI",
            targets: ["FeatureReceiveUI"]
        )
    ],
    dependencies: [
        .package(path: "../Analytics"),
        .package(path: "../Blockchain"),
        .package(path: "../Errors"),
        .package(path: "../FeatureKYC"),
        .package(path: "../Localization"),
        .package(path: "../FeatureTransaction"),
        .package(path: "../Tool")
    ],
    targets: [
        .target(
            name: "FeatureReceiveDomain",
            dependencies: [
                .product(name: "Errors", package: "Errors"),
                .product(name: "FeatureTransactionDomain", package: "FeatureTransaction"),
                .product(name: "FeatureTransactionUI", package: "FeatureTransaction"),
                .product(name: "Localization", package: "Localization"),
                .product(name: "ToolKit", package: "Tool")
            ]
        ),
        .target(
            name: "FeatureReceiveUI",
            dependencies: [
                .product(name: "AnalyticsKit", package: "Analytics"),
                .product(name: "BlockchainUI", package: "Blockchain"),
                .product(name: "ErrorsUI", package: "Errors"),
                .product(name: "FeatureKYCDomain", package: "FeatureKYC"),
                .product(name: "FeatureKYCUI", package: "FeatureKYC"),
                .product(name: "FeatureTransactionDomain", package: "FeatureTransaction"),
                .product(name: "Localization", package: "Localization"),
                .target(name: "FeatureReceiveDomain")
            ]
        ),
        .testTarget(
            name: "FeatureReceiveUITests",
            dependencies: [
                .target(name: "FeatureReceiveUI")
            ]
        )
    ]
)
