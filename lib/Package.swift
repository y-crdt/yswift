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
        .target(
            name: "YniffiWrapper",
            dependencies: [
                .target(name: "YniffiXC", condition: .when(platforms: [.iOS]))
            ],
            path: "swift/wrapper"
        ),
        .binaryTarget(
            name: "YniffiXC",
            path: "./YniffiXC.xcframework"
        ),
        .target(
            name: "Yniffi",
            dependencies: ["YniffiWrapper"],
            path: "swift/scaffold"
        )
    ]
)
