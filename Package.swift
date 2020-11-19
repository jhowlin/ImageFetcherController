// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "ImageFetcherController",
    
	platforms: [.iOS("12.0")],
    products: [
        .library(
            name: "ImageFetcherController",
            targets: ["ImageFetcherController"]),
    ],

    dependencies: [],
    targets: [
        .target(
            name: "ImageFetcherController",
            dependencies: [],
			path:"ImageFetcherController/Classes")
    ]
)
