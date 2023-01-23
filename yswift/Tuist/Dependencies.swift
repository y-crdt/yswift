import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: [
        .package(path: .relativeToRoot("../lib"))
    ],
    platforms: [.iOS]
)
