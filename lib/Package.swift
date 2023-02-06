// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "Yniffi",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "Yniffi", targets: ["Yniffi"]),
    ],
    dependencies: [
    ],
    targets: [
        /*
        * A placeholder wrapper for our binaryTarget so that Xcode will ensure this is
        * downloaded/built before trying to use it in the build process
        * A bit hacky but necessary for now https://github.com/mozilla/application-services/issues/4422
        */
//        .target(
//            name: "YniffiWrapper",
//            dependencies: [
//                .target(name: "YniffiFFI", condition: .when(platforms: [.iOS]))
//            ],
//            path: "swift/wrapper"
//        ),

// If you're getting the error 'does not contain expected binary artifact', then the 
// filename of the xcframework doesn't match the name module that's exposed within it.
// There's a *tight* coupling to the module name (case sensitive!!) and the name
// of the XCFramework. Annoying, yeah - but there it is.
// In addition to the name of the framework, the binary target name in Package.swift
// MUST be the same as the exported module. Without it, you'll get the same error.
// And there's some detail that if you use a compressed, remote framework and forgot to 
// compress it using ditto with the option '--keepParent', then it'll expand into a 
// different name, and again - wham - the same "does not contain the expected binary"
// error.

        .binaryTarget(
            name: "yniffiFFI",
            path: "./yniffiFFI.xcframework"
        ),
        .target(
            name: "Yniffi",
            dependencies: ["yniffiFFI"],
            path: "swift/scaffold"
        )
    ]
)
