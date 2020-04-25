// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "AppleDeveloperDiscoverRSSFeed",
    platforms: [.macOS(.v10_15)],
    products: [
        .executable(
            name: "AppleDeveloperDiscoverRSSFeed",
            targets: ["AppleDeveloperDiscoverRSSFeed"]),
    ],
    dependencies: [
        .package(url: "https://github.com/JohnSundell/Ink", from: "0.4.0"),
        .package(url: "https://github.com/alexaubry/HTMLString", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "AppleDeveloperDiscoverRSSFeed",
            dependencies: ["Ink", "HTMLString"]),
    ]
)
