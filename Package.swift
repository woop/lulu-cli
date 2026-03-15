// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "lulu-cli",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "lulu-cli",
            path: "Sources/LuLuCLI"
        )
    ]
)
