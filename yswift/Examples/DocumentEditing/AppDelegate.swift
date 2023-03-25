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
        let _ = document.getOrCreateText(named: "some_text")
        return document
    }()

    lazy var connectionManager = ConnectionManager(document: document)
    lazy var viewModel = DocumentViewModel(doc: document, connectionManager: connectionManager)

    private func setupNavigation() {
        let listViewController = UIHostingController(rootView: DocumentsListView(connectionManager: connectionManager))
        let documentViewController = UIHostingController(rootView: DocumentView(viewModel: viewModel))
        let navigationController = UINavigationController(rootViewController: listViewController)
        connectionManager.onPeerConnected = { _ in
            DispatchQueue.main.async {
                navigationController.pushViewController(documentViewController, animated: true)
            }
        }
        window?.rootViewController = navigationController
    }
}
