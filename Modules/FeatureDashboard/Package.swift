// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "FeatureDashboard",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .watchOS(.v7),
        .tvOS(.v14)
    ],
    products: [
        .library(name: "FeatureDashboard", targets: ["FeatureDashboardUI"]),
        .library(name: "FeatureDashboardUI", targets: ["FeatureDashboardUI"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/ReactiveX/RxSwift.git",
            from: "6.5.0"
        ),
        .package(
            url: "https://github.com/RxSwiftCommunity/RxDataSources.git",
            from: "5.0.2"
        ),
        .package(path: "../ComposableArchitectureExtensions"),
        .package(path: "../FeaturePaymentsIntegration"),
        .package(path: "../FeatureTransaction"),
        .package(path: "../FeatureWithdrawalLocks"),
        .package(path: "../Platform"),
        .package(path: "../Tool"),
        .package(path: "../UIComponents"),
        .package(path: "../FeatureBackupRecoveryPhrase")
    ],
    targets: [
        .target(
            name: "FeatureDashboardUI",
            dependencies: [
                .product(name: "ComposableNavigation", package: "ComposableArchitectureExtensions"),
                .product(name: "FeaturePlaidUI", package: "FeaturePaymentsIntegration"),
                .product(name: "FeatureTransactionUI", package: "FeatureTransaction"),
                .product(name: "FeatureWithdrawalLocksUI", package: "FeatureWithdrawalLocks"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "PlatformUIKit", package: "Platform"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RxDataSources", package: "RxDataSources"),
                .product(name: "RxRelay", package: "RxSwift"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "UIComponents", package: "UIComponents"),
                .product(name: "FeatureBackupRecoveryPhraseUI", package: "FeatureBackupRecoveryPhrase")
            ]
        ),
        .testTarget(
            name: "FeatureDashboardUITests",
            dependencies: [
                .target(name: "FeatureDashboardUI")
            ]
        )
    ]
)
