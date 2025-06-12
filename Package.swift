// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnalyticsProvider",
	platforms: [
		.iOS(.v17),
		.watchOS(.v10),
		.macOS(.v14),
		.visionOS(.v2)
	],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AnalyticsProvider",
            targets: ["AnalyticsProvider"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AnalyticsProvider"),
        .testTarget(
            name: "AnalyticsProviderTests",
            dependencies: ["AnalyticsProvider"]
        ),
    ]
)
