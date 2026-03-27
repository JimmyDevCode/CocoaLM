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
            url: "https://github.com/JimmyDevCode/CocoaLM/releases/download/0.1.1/llama.xcframework.zip",
            checksum: "01f3183fec1a6af553f8ffc76061d1a870629ddd66dded95c1746b816d7b0649"
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
