// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TreeSitterTextView",
    platforms: [
        .macOS(.v10_15),
        .macCatalyst(.v13),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v5),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "TreeSitterTextView", targets: ["TreeSitterTextView"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tree-sitter/swift-tree-sitter", .upToNextMinor(from: "0.9.0")),
    ],
    targets: [
        .target(
            name: "TreeSitterTextView",
            dependencies: [
                .product(name: "SwiftTreeSitter", package: "swift-tree-sitter"),
                .product(name: "SwiftTreeSitterLayer", package: "swift-tree-sitter")
            ]
        ),
        .testTarget(
            name: "TreeSitterTextViewTests",
            dependencies: ["TreeSitterTextView"]
        ),
    ]
)
