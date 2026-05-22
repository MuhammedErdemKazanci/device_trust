// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "device_trust",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "device-trust", targets: ["device_trust"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "device_trust",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                "device_trust_native"
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .target(
            name: "device_trust_native",
            cSettings: [
                .headerSearchPath("include/device_trust_native")
            ]
        )
    ]
)
