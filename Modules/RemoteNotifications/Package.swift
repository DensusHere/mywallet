// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "RemoteNotifications",
    platforms: [
        .iOS(.v15),
        .macOS(.v13),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "RemoteNotificationsKit",
            targets: ["RemoteNotificationsKit"]
        ),
        .library(
            name: "RemoteNotificationsKitMock",
            targets: ["RemoteNotificationsKitMock"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/dchatzieleftheriou-bc/DIKit.git",
            exact: "1.0.1"
        ),
        .package(path: "../Analytics"),
        .package(path: "../BlockchainComponentLibrary"),
        .package(path: "../BlockchainNamespace"),
        .package(path: "../Extensions"),
        .package(path: "../Localization"),
        .package(path: "../Network"),
        .package(path: "../Tool"),
        .package(path: "../FeatureAuthentication")
    ],
    targets: [
        .target(
            name: "RemoteNotificationsKit",
            dependencies: [
                .product(name: "AnalyticsKit", package: "Analytics"),
                .product(name: "BlockchainComponentLibrary", package: "BlockchainComponentLibrary"),
                .product(name: "BlockchainNamespace", package: "BlockchainNamespace"),
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "Extensions", package: "Extensions"),
                .product(name: "Localization", package: "Localization"),
                .product(name: "ToolKit", package: "Tool"),
                .product(name: "NetworkKit", package: "Network"),
                .product(name: "FeatureAuthenticationDomain", package: "FeatureAuthentication")
            ]
        ),
        .target(
            name: "RemoteNotificationsKitMock",
            dependencies: [
                .target(name: "RemoteNotificationsKit")
            ],
            resources: [
                .copy("remote-notification-registration-failure.json"),
                .copy("remote-notification-registration-success.json")
            ]
        ),
        .testTarget(
            name: "RemoteNotificationsKitTests",
            dependencies: [
                .target(name: "RemoteNotificationsKit"),
                .target(name: "RemoteNotificationsKitMock"),
                .product(name: "AnalyticsKitMock", package: "Analytics"),
                .product(name: "BlockchainComponentLibrary", package: "BlockchainComponentLibrary"),
                .product(name: "Extensions", package: "Extensions"),
                .product(name: "Localization", package: "Localization"),
                .product(name: "NetworkKitMock", package: "Network")
            ]
        )
    ]
)
