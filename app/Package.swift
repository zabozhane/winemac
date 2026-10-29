// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WineMac",
    platforms: [.macOS(.v14)],
    targets: [
        // Everything that does not need AppKit/SwiftUI lives here so it can be unit-tested.
        .target(name: "WinemacCore"),
        .executableTarget(name: "WineMac", dependencies: ["WinemacCore"]),
        .testTarget(name: "WinemacCoreTests", dependencies: ["WinemacCore"]),
    ]
)
