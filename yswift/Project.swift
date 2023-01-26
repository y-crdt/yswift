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
    dependencies: [.external(name: "Yniffi")]
)

let exampleDocumentEditing = Target(
    name: "DocumentEditing",
    platform: .iOS,
    product: .app,
    bundleId: "y-crdt.swift.example.document-editing",
    deploymentTarget: .iOS(targetVersion: "15.0", devices: .iphone),
    infoPlist: .extendingDefault(with: [
        "UILaunchStoryboardName": "LaunchScreen",
        "NSLocalNetworkUsageDescription": "YSwiftExample needs to use your phone’s data to discover devices nearby"
    ]),
    sources: ["Examples/DocumentEditing/**"],
    resources: ["Examples/DocumentEditing/LaunchScreen.storyboard"],
    dependencies: [.target(name: "YSwift")]
)

let exampleTodolist = Target(
    name: "Todolist",
    platform: .iOS,
    product: .app,
    bundleId: "y-crdt.swift.example.todolist",
    deploymentTarget: .iOS(targetVersion: "15.0", devices: .iphone),
    infoPlist: .extendingDefault(with: [
        "UILaunchStoryboardName": "LaunchScreen",
        "NSLocalNetworkUsageDescription": "YSwiftExample needs to use your phone’s data to discover devices nearby"
    ]),
    sources: ["Examples/Todolist/**"],
    resources: ["Examples/Todolist/LaunchScreen.storyboard"],
    dependencies: [.target(name: "YSwift")]
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
    targets: [mainTarget, exampleDocumentEditing, exampleTodolist, testTarget],
    fileHeaderTemplate: .none
)
