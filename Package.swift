// swift-tools-version: 6.4

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
        .executableTarget(
            name: "OpenCoreVideoRuntimeSmoke",
            dependencies: ["OpenCoreVideo"]
        ),
        .testTarget(
            name: "OpenCoreVideoTests",
            dependencies: ["OpenCoreVideo"]
        )
    ],
    swiftLanguageModes: [.v6]
)
