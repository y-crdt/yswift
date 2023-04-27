import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: [
        .local(path: "../")
    ],
    platforms: [.iOS]
)
