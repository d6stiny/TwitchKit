// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TwitchKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "TwitchKit",
            targets: ["TwitchKit"]),
    ],
    targets: [
        .target(
            name: "TwitchKit"),
        .testTarget(
            name: "TwitchKitTests",
            dependencies: ["TwitchKit"]
        ),
    ]
)
