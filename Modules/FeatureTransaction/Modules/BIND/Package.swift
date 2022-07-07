// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "BIND",
    platforms: [.macOS(.v11), .iOS(.v14)],
    products: [
        .library(name: "BINDWithdrawData", targets: ["BINDWithdrawData"]),
        .library(name: "BINDWithdrawDomain", targets: ["BINDWithdrawDomain"]),
        .library(name: "BINDWithdrawUI", targets: ["BINDWithdrawUI"])
    ],
    dependencies: [
        .package(path: "../../../BlockchainNamespace"),
        .package(path: "../../../BlockchainComponentLibrary"),
        .package(path: "../../../Errors"),
        .package(path: "../../../Network"),
        .package(path: "../../../Money"),
        .package(path: "../../../Tool")
    ],
    targets: [
        .target(
            name: "BINDWithdrawUI",
            dependencies: [
                .target(name: "BINDWithdrawDomain"),
                .product(name: "BlockchainComponentLibrary", package: "BlockchainComponentLibrary")
            ]
        ),
        .target(
            name: "BINDWithdrawDomain",
            dependencies: [
                .product(name: "BlockchainNamespace", package: "BlockchainNamespace"),
                .product(name: "Errors", package: "Errors"),
                .product(name: "MoneyKit", package: "Money"),
                .product(name: "ToolKit", package: "Tool")
            ]
        ),
        .target(
            name: "BINDWithdrawData",
            dependencies: [
                .target(name: "BINDWithdrawDomain"),
                .product(name: "NetworkKit", package: "Network")
            ]
        ),
        .testTarget(
            name: "BINDWithdrawUITests",
            dependencies: ["BINDWithdrawUI"]
        )
    ]
)
