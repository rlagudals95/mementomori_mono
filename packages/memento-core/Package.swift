// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MementoCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "MementoCore", targets: ["MementoCore"])],
    targets: [
        .target(name: "MementoCore"),
        .testTarget(name: "MementoCoreTests", dependencies: ["MementoCore"])
    ]
)
