
import PackageDescription

let package = Package(
    name: "ImageFetcherController",
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
