// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EdgeCore",
    platforms: [.macOS(.v14)],
    products: [.library(name: "EdgeCore", targets: ["EdgeCore"])],
    targets: [
        .target(name: "EdgeCore"),
        .testTarget(name: "EdgeCoreTests", dependencies: ["EdgeCore"]),
    ]
)
