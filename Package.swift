// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SubtitleCover",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "SubtitleCover"),
    ]
)
