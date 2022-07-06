// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FeatureReferral",
    defaultLocalization: "en",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(name: "FeatureReferral", targets: [
            "FeatureReferralDomain",
            "FeatureReferralData",
            "FeatureReferralUI",
            "FeatureReferralMocks"
        ]),
        .library(
            name: "FeatureReferralDomain",
            targets: ["FeatureReferralDomain"]
        ),
        .library(
            name: "FeatureReferralData",
            targets: ["FeatureReferralData"]
        ),
        .library(
            name: "FeatureReferralUI",
            targets: ["FeatureReferralUI"]
        ),
        .library(
            name: "FeatureReferralMocks",
            targets: ["FeatureReferralMocks"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "0.34.0"
        ),
        .package(path: "../Analytics"),
        .package(path: "../BlockchainComponentLibrary"),
        .package(path: "../ComposableArchitectureExtensions"),
        .package(path: "../Localization"),
        .package(path: "../Network"),
        .package(path: "../Errors"),
        .package(path: "../Tool"),
        .package(path: "../UIComponents"),
        .package(path: "../Platform")
    ],
    targets: [
        .target(
            name: "FeatureReferralDomain",
            dependencies: [
                .product(
                    name: "Errors",
                    package: "Errors"
                ),
                .product(
                    name: "Localization",
                    package: "Localization"
                ),
                .product(
                    name: "BlockchainComponentLibrary",
                    package: "BlockchainComponentLibrary"
                ),
                .product(name: "PlatformKit", package: "Platform")
            ],
            path: "Sources/FeatureReferralDomain"
        ),
        .target(
            name: "FeatureReferralData",
            dependencies: [
                .target(
                    name: "FeatureReferralDomain"
                ),
                .product(
                    name: "NetworkKit",
                    package: "Network"
                ),
                .product(
                    name: "Errors",
                    package: "Errors"
                )
            ],
            path: "Sources/FeatureReferralData"
        ),
        .target(
            name: "FeatureReferralUI",
            dependencies: [
                .target(name: "FeatureReferralDomain"),
                .target(name: "FeatureReferralMocks"),
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
                    name: "Errors",
                    package: "Errors"
                ),
                .product(
                    name: "ComposableArchitectureExtensions",
                    package: "ComposableArchitectureExtensions"
                ),
                .product(
                    name: "UIComponents",
                    package: "UIComponents"
                )
            ],
            path: "Sources/FeatureReferralUI"
        ),
        .target(
            name: "FeatureReferralMocks",
            dependencies: [
                .target(name: "FeatureReferralDomain")
            ],
            path: "Sources/Mocks"
        )
    ]
)
