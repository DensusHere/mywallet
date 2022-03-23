// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Blockchain",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "AnalyticsKit",
            targets: ["AnalyticsKit"]
        ),
        .library(
            name: "BlockchainComponentLibrary",
            targets: ["BlockchainComponentLibrary"]
        ),
        .library(
            name: "BlockchainNamespace",
            targets: ["BlockchainNamespace"]
        ),
        .library(
            name: "FeatureOpenBankingUI",
            targets: ["FeatureOpenBankingUI"]
        ),
        .library(
            name: "FeatureOpenBankingDomain",
            targets: ["FeatureOpenBankingDomain"]
        ),
        .library(
            name: "FeatureOpenBankingData",
            targets: ["FeatureOpenBankingData"]
        ),
        .library(
            name: "ComposableNavigation",
            targets: ["ComposableNavigation"]
        ),
        .library(
            name: "NetworkError",
            targets: ["NetworkError"]
        ),
        .library(
            name: "WalletNetworkKit",
            targets: ["WalletNetworkKit"]
        ),
        .library(
            name: "ToolKit",
            targets: ["ToolKit"]
        ),
        .library(
            name: "UIComponentsKit",
            targets: ["UIComponentsKit"]
        )
    ],
    dependencies: [
        .package(
            name: "combine-schedulers",
            url: "https://github.com/pointfreeco/combine-schedulers",
            from: "0.5.0"
        ),
        .package(
            name: "swift-composable-architecture",
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "0.32.0"
        ),
        .package(
            name: "swift-case-paths",
            url: "https://github.com/pointfreeco/swift-case-paths",
            from: "0.7.0"
        ),
        .package(
            name: "DIKit",
            url: "https://github.com/jackpooleybc/DIKit.git",
            .branch("safe-property-wrappers")
        ),
        .package(
            name: "BigInt",
            url: "https://github.com/attaswift/BigInt.git",
            from: "5.2.1"
        ),
        .package(
            name: "swift-markdown",
            url: "https://github.com/apple/swift-markdown.git",
            .revision("1023300b1d6847360ac9ceebbcff2bccacbcf2a5")
        ),
        .package(
            name: "Lexicon",
            url: "https://github.com/screensailor/Lexicon",
            .revision("160c4c417f8490658a8396d0283fb0d6fb98c327")
        ),
        .package(
            name: "swift-algorithms",
            url: "https://github.com/apple/swift-algorithms.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "AnalyticsKit",
            path: "Modules/Analytics/Sources/AnalyticsKit"
        ),
        .testTarget(
            name: "AnalyticsKitTests",
            path: "Modules/Analytics/Tests/AnalyticsKitTests"
        ),
        .target(
            name: "BlockchainComponentLibrary",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "Markdown", package: "swift-markdown")
            ],
            path: "Modules/BlockchainComponentLibrary/Sources/BlockchainComponentLibrary",
            resources: [
                .process("Resources/Fonts")
            ]
        ),
        .testTarget(
            name: "BlockchainComponentLibraryTests",
            path: "Modules/BlockchainComponentLibrary/Tests/BlockchainComponentLibraryTests"
        ),
        .target(
            name: "BlockchainNamespace",
            dependencies: [
                .target(name: "AnyCoding"),
                .target(name: "FirebaseProtocol"),
                .product(name: "Lexicon", package: "Lexicon")
            ],
            path: "Modules/BlockchainNamespace/Sources/BlockchainNamespace",
            resources: [
                .copy("blockchain.taskpaper")
            ]
        ),
        .target(
            name: "AnyCoding",
            path: "Modules/BlockchainNamespace/Sources/AnyCoding"
        ),
        .target(
            name: "FirebaseProtocol",
            path: "Modules/BlockchainNamespace/Sources/FirebaseProtocol"
        ),
        .target(
            name: "ComposableNavigation",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .target(name: "BlockchainComponentLibrary")
            ],
            path: "Modules/ComposableArchitectureExtensions/Sources/ComposableNavigation",
            exclude: [
                "README.md"
            ]
        ),
        .target(
            name: "NetworkError",
            path: "Modules/NetworkErrors/Sources/NetworkError"
        ),
        .target(
            name: "WalletNetworkKit",
            dependencies: [
                .product(name: "DIKit", package: "DIKit"),
                .target(name: "AnalyticsKit"),
                .target(name: "ToolKit"),
                .target(name: "NetworkError")
            ],
            path: "Modules/Network/Sources/NetworkKit"
        ),
        .target(
            name: "ToolKit",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "CasePaths", package: "swift-case-paths"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "BigInt", package: "BigInt")
            ],
            path: "Modules/Tool/Sources/ToolKit"
        ),
        .target(
            name: "UIComponentsKit",
            dependencies: [
                .product(name: "CasePaths", package: "swift-case-paths"),
                .target(name: "ToolKit"),
                .target(name: "BlockchainComponentLibrary")
            ],
            path: "Modules/UIComponents/UIComponentsKit",
            resources: [
                .copy("Lottie/loader_v2.json")
            ]
        ),
        .target(
            name: "FeatureOpenBankingDomain",
            dependencies: [
                .product(name: "CombineSchedulers", package: "combine-schedulers"),
                .product(name: "CasePaths", package: "swift-case-paths"),
                .target(name: "NetworkError"),
                .target(name: "BlockchainNamespace"),
                .target(name: "ToolKit")
            ],
            path: "Modules/FeatureOpenBanking/Sources/FeatureOpenBankingDomain"
        ),
        .target(
            name: "FeatureOpenBankingData",
            dependencies: [
                .product(name: "CombineSchedulers", package: "combine-schedulers"),
                .target(name: "FeatureOpenBankingDomain"),
                .target(name: "WalletNetworkKit"),
                .target(name: "BlockchainNamespace"),
                .target(name: "ToolKit")
            ],
            path: "Modules/FeatureOpenBanking/Sources/FeatureOpenBankingData"
        ),
        .target(
            name: "FeatureOpenBankingUI",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .target(name: "FeatureOpenBankingDomain"),
                .target(name: "FeatureOpenBankingData"),
                .target(name: "ComposableNavigation"),
                .target(name: "BlockchainComponentLibrary"),
                .target(name: "UIComponentsKit")
            ],
            path: "Modules/FeatureOpenBanking/Sources/FeatureOpenBankingUI"
        )
    ],
    swiftLanguageVersions: [.v5]
)
