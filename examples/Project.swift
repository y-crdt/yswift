import ProjectDescription

let dependencies = Dependencies(
    swiftPackageManager: [
        .local(path: ".."),
    ],
    platforms: [.iOS]
)

let exampleTodolist = Target(
    name: "TodoListExample",
    platform: .iOS,
    product: .app,
    bundleId: "y-crdt.swift.example.todolist",
    deploymentTarget: .iOS(targetVersion: "15.0", devices: .iphone),
    infoPlist: .extendingDefault(with: [
        "UILaunchStoryboardName": "LaunchScreen",
        "NSLocalNetworkUsageDescription": "TodoListExample needs to use your phone’s data to discover devices nearby",
    ]),
    sources: ["Examples/Todolist/**"],
    resources: ["Examples/Todolist/LaunchScreen.storyboard"],
    dependencies: [.external(name: "YSwift")]
)

let project = Project(
    name: "YSwiftExamples",
    organizationName: "y-crdt",
    targets: [exampleTodolist],
    fileHeaderTemplate: .none
)
