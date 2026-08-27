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
// The binary target is the locally built XCFramework whenever one exists next
// to this manifest — `./scripts/build-xcframework.sh` puts it there, and so
// does a vendoring build that produces it from lib/ — and the released
// download otherwise. `YSWIFT_LOCAL` still forces the local path (and fails
// loudly if nothing has been built) for anyone who wants that guarantee.
//
// Using a local XCFramework has one known cost: swift-docc-plugin cannot
// extract symbols from it through Swift Package Manager. Building
// documentation within Xcode works; for HTML docs use
// `./scripts/build-ghpages-docs.sh`.
let localXCFramework = Context.packageDirectory + "/lib/yniffiFFI.xcframework"
if ProcessInfo.processInfo.environment["YSWIFT_LOCAL"] != nil
    || FileManager.default.fileExists(atPath: localXCFramework) {
    FFIbinaryTarget = .binaryTarget(
            name: "yniffiFFI",
            path: "./lib/yniffiFFI.xcframework"
    )
} else {

    FFIbinaryTarget = .binaryTarget(
            name: "yniffiFFI",
            url: "https://github.com/y-crdt/yswift/releases/download/0.2.1/yniffiFFI.xcframework.zip",
            checksum: "7377378b6d8bb628ff8e2847f73a6b7115705d53a822dd578fb9cbcf2bce1675"
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
