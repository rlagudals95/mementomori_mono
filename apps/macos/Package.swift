// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MementoMori",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "MementoMori", targets: ["MementoMori"])],
    targets: [
        .target(name: "MementoCore"),
        .executableTarget(name: "MementoMori", dependencies: ["MementoCore"], resources: [.copy("Resources")]),
        .testTarget(name: "MementoCoreTests", dependencies: ["MementoCore"])
    ]
)
