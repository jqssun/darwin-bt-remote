// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BTHIDKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [.library(name: "BTHIDKit", targets: ["BTHIDKit"])],
    targets: [
        .target(name: "BTHIDKit", resources: [.process("Resources")])
    ]
)
