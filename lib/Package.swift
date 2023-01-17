// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "YNativeFinal",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "YNativeFinal", targets: ["YNativeFinal"]),
    ],
    dependencies: [
    ],
    targets: [
        /*
        * A placeholder wrapper for our binaryTarget so that Xcode will ensure this is
        * downloaded/built before trying to use it in the build process
        * A bit hacky but necessary for now https://github.com/mozilla/application-services/issues/4422
        */
        .target(
            name: "YNativeBinaryWrapper",
            dependencies: [
                .target(name: "YNativeBinary", condition: .when(platforms: [.iOS]))
            ],
            path: "swift/wrapper"
        ),
        .binaryTarget(
            name: "YNativeBinary",
            path: "./YNativeBinary.xcframework"
        ),
        .target(
            name: "YNativeFinal",
            dependencies: ["YNativeBinaryWrapper"],
            path: "swift/scaffold"
        )
    ]
)
