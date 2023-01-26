import Foundation
import Combine
import YSwift

final class DocumentViewModel: ObservableObject {
    var connectionManager: ConnectionManager
    @Published var text: String = ""
    private var bag = Set<AnyCancellable>()
    private var doc: YDocument
    
    init(doc: YDocument, connectionManager: ConnectionManager) {
        self.doc = doc
        self.connectionManager = connectionManager
        $text.sink { [weak self] newText in
            guard let self = self else { return }
            if self.skipNextTextChange {
                self.skipNextTextChange = false
            } else {
                self.syncUpdates(oldText: self.text, newText: newText)
            }
        }
        .store(in: &bag)
        connectionManager.onUpdatesReceived = { [weak self] in
            guard let self = self else { return }
            self.refresh()
        }
    }
    
    // @TODO: make better integration with `TextEditor`/`UITextView`, because this one doesn't handle all the cases correctly.
    private func syncUpdates(oldText: String, newText: String) {
        let ytext = doc.getOrCreateText(named: "some_text")
        let old = Array(oldText)
        let new = Array(newText)
        let changes = diff(old: old, new: new)
        
        let update: Buffer = doc.transact { txn in
            for change in changes {
                switch change {
                case let .insert(insertion):
                    ytext.insert(tx: txn, index: UInt32(insertion.index), chunk: String(insertion.item))
                case let .replace(replace):
                    ytext.removeRange(tx: txn, start: UInt32(replace.index), length: 1)
                    ytext.insert(tx: txn, index: UInt32(replace.index), chunk: String(replace.newItem))
                case let .delete(deletion):
                    ytext.removeRange(tx: txn, start: UInt32(deletion.index), length: 1)
                default: break
                }
            }
            
            return txn.transactionEncodeUpdate()
        }
        connectionManager.sendEveryone(.init(kind: .UPDATE, buffer: update))
    }
    
    var skipNextTextChange = false
    
    private func refresh() {
        let newText: String? = doc.transact { txn in
            return txn.transactionGetText(name: "some_text")?.getString(tx: txn)
        }
        
        DispatchQueue.main.async {
            self.skipNextTextChange = true
            self.text = newText ?? ""
        }
    }
}
