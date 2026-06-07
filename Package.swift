// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "rili",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "rili",
            path: "Sources/rili"
        )
    ]
)
