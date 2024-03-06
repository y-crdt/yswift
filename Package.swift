// swift-tools-version:5.6

import PackageDescription
import Foundation

var globalSwiftSettings: [PackageDescription.SwiftSetting] = []

// Only enable if Swift 5.7+ is available and the environment variable `LOCALDEV` is
// set to a value (such as 'true')
#if swift(>=5.7)
    if ProcessInfo.processInfo.environment["YSWIFT_LOCAL"] != nil {
        /*
        Summation from https://www.donnywals.com/enabling-concurrency-warnings-in-xcode-14/
        Set `strict-concurrency` to `targeted` to enforce Sendable and actor-isolation
        checks in your code. This explicitly verifies that `Sendable` constraints are
        met when you mark one of your types as `Sendable`.

        This mode is essentially a bit of a hybrid between the behavior that's intended
        in Swift 6, and the default in Swift 5.7. Use this mode to have a bit of
        checking on your code that uses Swift concurrency without too many warnings
        and / or errors in your current codebase.

        Set `strict-concurrency` to `complete` to get the full suite of concurrency
        constraints, essentially as they will work in Swift 6.
        */
        globalSwiftSettings.append(.unsafeFlags(["-Xfrontend", "-strict-concurrency=complete"]))
    }
#endif

let FFIbinaryTarget: PackageDescription.Target
// If either the environment variable `YSWIFT_LOCAL` is set to any value, the packages uses
// a local reference to an XCFramework file (built from `./scripts/build-xcframework.sh`)
// rather than the previous released version.
//
// The script `./scripts/build-xcframework.sh` _does_ expect that you have Rust
// installed locally in order to function.
if ProcessInfo.processInfo.environment["YSWIFT_LOCAL"] != nil {
    // We are using a local file reference to an XCFramework, which is functional
    // on the tags for this package because the XCFramework.zip file is committed with
    // those specific release points. This does, however, cause a few awkward issues,
    // in particular it means that swift-docc-plugin doesn't operate correctly as the
    // process to retrieve the symbols from this and the XCFramework fails within
    // Swift Package Manager. Building documentation within Xcode works perfectly fine,
    // but if you're attempting to generate HTML documentation, use the script
    // `./scripts/build-ghpages-docs.sh`.
    FFIbinaryTarget = .binaryTarget(
            name: "yniffiFFI",
            path: "./lib/yniffiFFI.xcframework"
    )
} else {
    FFIbinaryTarget = .binaryTarget(
            name: "yniffiFFI",
            url: "https://github.com/y-crdt/yswift/releases/download/0.2.0/yniffiFFI.xcframework.zip",
            checksum: "d2633bdb1e9f257cd56a852f360f0d0f4bc1615a4c34a05e76a2da2c430a0f98"
    )
}

let package = Package(
    name: "YSwift",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(name: "YSwift", targets: ["YSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
    ],
    targets: [
        FFIbinaryTarget,
        .target(
            name: "Yniffi",
            dependencies: ["yniffiFFI"],
            path: "lib/swift/scaffold"
        ),
        .target(
            name: "YSwift",
            dependencies: ["Yniffi"],
            swiftSettings: globalSwiftSettings
        ),
        .testTarget(
            name: "YSwiftTests",
            dependencies: ["YSwift"]
        ),
    ]
)
