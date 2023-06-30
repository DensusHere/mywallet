// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "FeatureAttribution",
    platforms: [
        .iOS(.v15),
        .macOS(.v13),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "FeatureAttribution",
            targets: ["FeatureAttributionDomain", "FeatureAttributionData"]
        ),
        .library(
            name: "FeatureAttributionDomain",
            targets: ["FeatureAttributionDomain"]
        ),
        .library(
            name: "FeatureAttributionData",
            targets: ["FeatureAttributionData"]
        )
    ],
    dependencies: [
        .package(path: "../Tool"),
        .package(path: "../Network"),
        .package(path: "../Errors"),
        .package(path: "../BlockchainNamespace")
    ],
    targets: [
        .target(
            name: "FeatureAttributionData",
            dependencies: [
                .target(name: "FeatureAttributionDomain"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "NetworkKit", package: "Network")
            ]
        ),
        .target(
            name: "FeatureAttributionDomain",
            dependencies: [
                .product(name: "BlockchainNamespace", package: "BlockchainNamespace"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "Errors", package: "Errors")
            ]
        )
    ]
)
