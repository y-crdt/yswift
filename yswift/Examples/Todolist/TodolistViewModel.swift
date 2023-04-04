import Combine
import MultipeerConnectivity
import SwiftUI
import YSwift

enum ConnectionState: String {
    case connecting = "Connecting..."
    case connected = "Connected"
    case notConnected = "Offline"

    init?(_ sessionState: MCSessionState) {
        switch sessionState {
        case .notConnected:
            self = .notConnected
        case .connecting:
            self = .connecting
        case .connected:
            self = .connected
        @unknown default:
            return nil
        }
    }
}

final class TodolistViewModel: ObservableObject {
    @Published var connectionState: ConnectionState?
    let items: YArray<TodoItem>
    
    private let connectionManager: ConnectionManager
    private let document: YDocument

    init(connectionManager: ConnectionManager, document: YDocument) {
        self.connectionManager = connectionManager
        self.document = document
        self.items = document.getOrCreateArray(named: "TodoItem")

        connectionManager.onUpdatesReceived = { [weak self] in
            self?.reloadUI()
        }
        
        connectionManager.onConnectionStateChanged = { [weak self] sessionState in
            DispatchQueue.main.async {
                self?.connectionState = .init(sessionState)
            }
        }
    }

    func disconnect() {
        connectionManager.disconnect()
    }

    func connect() {
        connectionManager.connect()
    }

    func toggleItem(_ item: TodoItem) {
        guard let index = items.firstIndex(of: item) else { return }
        
        var newItem = item
        newItem.isCompleted.toggle()

        let update: Buffer = document.transactSync { [weak self] txn in
            guard let self = self else { return [] }
            self.items.remove(at: index, transaction: txn)
            self.items.insert(at: index, value: newItem, transaction: txn)
            return txn.transactionEncodeUpdate()
        }
        
        propagateUpdate(update)
    }

    func addItem(_ item: TodoItem) {
        let update: Buffer = document.transactSync { [weak self] txn in
            guard let self = self else { return [] }
            self.items.append(item, transaction: txn)
            return txn.transactionEncodeUpdate()
        }
        propagateUpdate(update)
    }

    func removeItem(_ item: TodoItem) {
        guard let index = items.firstIndex(of: item) else { return }
        let update: Buffer = document.transactSync { [weak self] txn in
            guard let self = self else { return [] }
            self.items.remove(at: index, transaction: txn)
            return txn.transactionEncodeUpdate()
        }
        propagateUpdate(update)
    }
    
    private func propagateUpdate(_ update: Buffer) {
        guard !update.isEmpty else { return }
        reloadUI()
        connectionManager.sendEveryone(.init(kind: .UPDATE, buffer: update))
    }

    private func reloadUI() {
        DispatchQueue.main.async {
            withAnimation(.default) {
                self.objectWillChange.send()
            }
        }
    }
}
