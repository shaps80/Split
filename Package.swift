// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Split",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Split",
            targets: ["Split"]
        ),
    ],
    targets: [
        .target(
            name: "Split"
        )
    ]
)
