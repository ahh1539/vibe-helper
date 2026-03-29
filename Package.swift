// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VibeHelper",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "VibeHelper",
            path: "VibeHelper"
        ),
    ]
)
