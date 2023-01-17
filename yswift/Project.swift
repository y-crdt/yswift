import ProjectDescription

let mainTarget = Target(
    name: "YSwift",
    platform: .iOS,
    product: .framework,
    bundleId: "y-crdt.swift",
    deploymentTarget: .iOS(targetVersion: "13.0", devices: .iphone),
    infoPlist: .default,
    sources: ["Sources/**"],
    headers: .allHeaders(from: "Sources/**/*", umbrella: .relativeToRoot("Sources/yswift.h")),
    dependencies: [.external(name: "YNativeFinal")]
)

let testTarget = Target(
    name: "YSwiftTests",
    platform: .iOS,
    product: .unitTests,
    bundleId: "y-crdt.swift.tests",
    infoPlist: .default,
    sources: ["Tests/**"],
    dependencies: [.target(name: "YSwift")]
)

let project = Project(
    name: "YSwift",
    organizationName: "y-crdt",
    targets: [mainTarget, testTarget],
    fileHeaderTemplate: .string("")
)
