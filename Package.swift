// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "AnalyticsProvider",
	platforms: [
		.iOS(.v15),
		.watchOS(.v8),
		.macOS(.v12),
		.visionOS(.v1)
	],
    products: [
        .library(
            name: "AnalyticsProvider",
            targets: ["AnalyticsProvider"]
        ),
    ],
    targets: [
        .target(
            name: "AnalyticsProvider"),
        .testTarget(
            name: "AnalyticsProviderTests",
            dependencies: ["AnalyticsProvider"]
        ),
    ]
)
