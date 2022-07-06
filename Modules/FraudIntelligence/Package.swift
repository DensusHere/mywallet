// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "FraudIntelligence",
    platforms: [.iOS(.v14), .macOS(.v12)],
    products: [
        .library(
            name: "FraudIntelligence",
            targets: ["FraudIntelligence"]
        )
    ],
    dependencies: [
        .package(path: "../BlockchainNamespace")
    ],
    targets: [
        .target(
            name: "FraudIntelligence",
            dependencies: [
                .product(name: "BlockchainNamespace", package: "BlockchainNamespace")
            ]
        ),
        .testTarget(
            name: "FraudIntelligenceTests",
            dependencies: ["FraudIntelligence"]
        )
    ]
)
