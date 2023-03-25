import SwiftUI
import UIKit
import YSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        setupNavigation()
        return true
    }

    lazy var document: YDocument = {
        let document = YDocument()
        let _: YYArray<TodoItem> = document.getOrCreateArray(named: "todo_items")
        return document
    }()

    lazy var connectionManager = ConnectionManager(document: document)
    lazy var viewModel = TodolistViewModel(connectionManager: connectionManager, document: document)

    private func setupNavigation() {
        let vc = UIHostingController(rootView: TodolistView(viewModel: viewModel))
        let navigationController = UINavigationController(rootViewController: vc)
        window?.rootViewController = navigationController
    }
}
