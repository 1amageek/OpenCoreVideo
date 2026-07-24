// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "OpenCoreVideo",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "OpenCoreVideo",
            targets: ["OpenCoreVideo"]
        )
    ],
    targets: [
        .target(
            name: "OpenCoreVideo"
        ),
        .testTarget(
            name: "OpenCoreVideoTests",
            dependencies: ["OpenCoreVideo"]
        )
    ],
    swiftLanguageModes: [.v6]
)
