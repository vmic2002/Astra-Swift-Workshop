// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Astra-Swift-Workshop",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Astra-Swift-Workshop",
            dependencies: ["AstraController", "Model"]
        ),
        .target(
            name: "AstraController",
            dependencies: ["Model", "Env"]
        ),
        .target(name: "Model"),
        .target(name: "Env")
        //.executableTarget(
          //  name: "Astra-Swift-Workshop",
            //dependencies: []),
        //.testTarget(
          //  name: "Astra-Swift-WorkshopTests",
            //dependencies: ["Astra-Swift-Workshop"]),
    ]
)
