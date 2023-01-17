import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: [
        .package(path: .relativeToRoot("../lib"))
//        .package(url: "https://github.com/nugmanoff/ynative-xcframework", .branch("main"))
    ],
    platforms: [.iOS]
)
