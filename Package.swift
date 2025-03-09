// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftAI",
    platforms: [.macOS(.v15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .visionOS(.v1)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AI",
            targets: ["AI"]),
        .library(
            name: "OpenAI",
            targets: ["OpenAI"]),

    ],
    dependencies: [
        .package(url: "https://github.com/LuisAbraham22/swift-openapi-client.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Examples",
            dependencies: [
                "AI",
                "OpenAI",
            ]
        ),
        .target(
            name: "AI"),
        .target(
            name: "OpenAI",
            dependencies: [
                "AI",
                .product(name: "OpenAIClient", package: "swift-openapi-client"),
            ]),
        .testTarget(
            name: "AITest",
            dependencies: ["AI"]
        ),
    ]
)
