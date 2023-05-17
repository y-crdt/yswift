import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: [
        .remote(url: "https://github.com/y-crdt/yswift", requirement: .upToNextMajor(from: "0.1.0")),
    ],
    platforms: [.iOS]
)
