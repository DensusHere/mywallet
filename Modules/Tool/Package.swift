// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Tool",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .watchOS(.v7),
        .tvOS(.v14)
    ],
    products: [
        .library(
            name: "ToolKit",
            targets: ["ToolKit"]
        ),
        .library(
            name: "ToolKitMock",
            targets: ["ToolKitMock"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/dchatzieleftheriou-bc/DIKit.git",
            branch: "safe-property-wrappers-locks"
        ),
        .package(
            url: "https://github.com/attaswift/BigInt.git",
            from: "5.3.0"
        ),
        .package(path: "../BlockchainNamespace"),
        .package(path: "../Extensions"),
        .package(path: "../Test")
    ],
    targets: [
        .target(
            name: "ToolKit",
            dependencies: [
                .product(name: "DIKit", package: "DIKit"),
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "Extensions", package: "Extensions"),
                .product(name: "BlockchainNamespace", package: "BlockchainNamespace")
            ]
        ),
        .target(
            name: "ToolKitMock",
            dependencies: [
                .target(name: "ToolKit")
            ]
        ),
        .testTarget(
            name: "ToolKitTests",
            dependencies: [
                .target(name: "ToolKit"),
                .target(name: "ToolKitMock"),
                .product(name: "TestKit", package: "Test")
            ]
        )
    ]
)
