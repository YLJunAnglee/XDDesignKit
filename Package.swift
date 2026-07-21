// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "XDDesignKit",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "XDDesignKit",
            targets: ["XDDesignKit"]
        ),
    ],
    targets: [
        .target(
            name: "XDDesignKit",
            exclude: [
                "Components/Button/DESIGN.md",
                "Theme/TYPOGRAPHY.md"
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "XDDesignKitTests",
            dependencies: ["XDDesignKit"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
    ]
)
