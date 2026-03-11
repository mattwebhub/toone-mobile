// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TooneMobileDeps",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.0"),
    ],
    targets: [
        .target(name: "TooneMobileDeps", dependencies: [
            .product(name: "MarkdownUI", package: "swift-markdown-ui"),
        ]),
    ]
)
