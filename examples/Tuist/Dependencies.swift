import ProjectDescription

let packages: [Package] = [
    .package(url: "https://github.com/y-crdt/yswift", from: "0.1.0"),
]

let dependencies = Dependencies(
    swiftPackageManager: SwiftPackageManagerDependencies(
        packages
    ),
    platforms: [.iOS]
)
