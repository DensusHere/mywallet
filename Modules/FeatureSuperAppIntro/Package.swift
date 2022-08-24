// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FeatureSuperAppIntro",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .watchOS(.v7),
        .tvOS(.v14)
    ],
    products: [
        .library(
            name: "FeatureSuperAppIntro",
            targets: ["FeatureSuperAppIntroUI"]
        ),
        .library(
            name: "FeatureSuperAppIntroUI",
            targets: ["FeatureSuperAppIntroUI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.24.0"),
        .package(name: "DIKit", url: "https://github.com/jackpooleybc/DIKit.git", .branch("safe-property-wrappers")),
        .package(path: "../Tool"),
        .package(path: "../ComposableArchitectureExtensions"),
        .package(path: "../BlockchainComponentLibrary"),
        .package(path: "../BlockchainNamespace")
    ],
    targets: [
        .target(
            name: "FeatureSuperAppIntroUI",
            dependencies: [
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(
                    name: "BlockchainComponentLibrary",
                    package: "BlockchainComponentLibrary"
                )
            ]
        )
    ]
)
