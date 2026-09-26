// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MementoMori",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "MementoMori", targets: ["MementoMori"])],
    dependencies: [.package(path: "../../packages/memento-core")],
    targets: [
        .executableTarget(name: "MementoMori", dependencies: [.product(name: "MementoCore", package: "memento-core")], resources: [.copy("Resources")])
    ]
)
