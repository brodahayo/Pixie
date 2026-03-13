// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotchyDeps",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.4.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.6.0"),
    ],
    targets: [
        .target(name: "NotchyDeps", dependencies: [
            .product(name: "Markdown", package: "swift-markdown"),
            .product(name: "Sparkle", package: "Sparkle"),
        ]),
    ]
)
