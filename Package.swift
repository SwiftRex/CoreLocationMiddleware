// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoreLocationMiddleware",
    // TODO: Review version requirements
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CoreLocationMiddleware",
            targets: ["CoreLocationMiddleware"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/SwiftRex/SwiftRex.git", from: "0.8.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CoreLocationMiddleware",
            dependencies: [.product(name: "CombineRex", package: "SwiftRex")]
        ),
        .testTarget(
            name: "CoreLocationMiddlewareTests",
            dependencies: ["CoreLocationMiddleware"]
        ),
    ]
)
