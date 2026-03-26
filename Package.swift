// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "CocoaLM",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "CocoaLM",
            targets: ["CocoaLM"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "llama",
            path: "../Vendor/llama.cpp/build-apple/llama.xcframework"
        ),
        .target(
            name: "CocoaLMBridge",
            dependencies: ["llama"],
            path: "Sources/CocoaLMBridge",
            publicHeadersPath: "include"
        ),
        .target(
            name: "CocoaLM",
            dependencies: ["CocoaLMBridge"],
            path: "Sources/CocoaLM"
        ),
        .testTarget(
            name: "CocoaLMTests",
            dependencies: ["CocoaLM"],
            path: "Tests/CocoaLMTests"
        )
    ]
)
