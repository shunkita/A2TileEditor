// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "A2te",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "A2te", targets: ["A2te"])
    ],
    targets: [
        .target(
            name: "A2teCore",
            path: "Sources/A2teCore"
        ),
        .executableTarget(
            name: "A2te",
            dependencies: ["A2teCore"],
            path: "Sources/A2te"
        )
    ]
)
