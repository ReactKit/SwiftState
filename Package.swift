// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "SwiftState",
    platforms: [.iOS(.v11)],
    products: [
       .library(name: "SwiftState", targets: ["SwiftState"])
    ],
    targets: [
       .target(name: "SwiftState", path: "Sources")
    ]
)
