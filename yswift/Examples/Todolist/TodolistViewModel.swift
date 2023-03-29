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
    private let connectionManager: ConnectionManager
    private let document: YDocument

    init(connectionManager: ConnectionManager, document: YDocument) {
        self.connectionManager = connectionManager
        self.document = document

        connectionManager.onUpdatesReceived = { [weak self] in
            guard let self = self else { return }
            self.refresh()
        }
        connectionManager.onConnectionStateChanged = { [weak self] sessionState in
            DispatchQueue.main.async {
                self?.connectionState = .init(sessionState)
            }
        }
    }

    var items: [TodoItem] {
        document.transactSync { txn in
            let items = YYArray<TodoItem>(array: txn.transactionGetArray(name: "todo_items")!)
            return items.toArray(tx: txn)
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

        let update: Buffer = document.transactSync { txn in
            let items = YYArray<TodoItem>(array: txn.transactionGetArray(name: "todo_items")!)
            items.remove(tx: txn, index: index)
            items.insert(tx: txn, index: index, value: newItem)
            return txn.transactionEncodeUpdate()
        }

        withAnimation(.default) {
            objectWillChange.send()
        }
        connectionManager.sendEveryone(.init(kind: .UPDATE, buffer: update))
    }

    func addItem(_ item: TodoItem) {
        let update: Buffer = document.transactSync { txn in
            let items = YYArray<TodoItem>(array: txn.transactionGetArray(name: "todo_items")!)
            items.pushBack(tx: txn, value: item)
            return txn.transactionEncodeUpdate()
        }
        withAnimation(.default) {
            objectWillChange.send()
        }
        connectionManager.sendEveryone(.init(kind: .UPDATE, buffer: update))
    }

    func removeItem(_ item: TodoItem) {
        guard let index = items.firstIndex(of: item) else { return }
        let update: Buffer = document.transactSync { txn in
            let items = YYArray<TodoItem>(array: txn.transactionGetArray(name: "todo_items")!)
            items.remove(tx: txn, index: index)
            return txn.transactionEncodeUpdate()
        }
        withAnimation(.default) {
            objectWillChange.send()
        }
        connectionManager.sendEveryone(.init(kind: .UPDATE, buffer: update))
    }

    private func refresh() {
        DispatchQueue.main.async {
            withAnimation(.default) {
                self.objectWillChange.send()
            }
        }
    }
}
