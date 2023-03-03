import Foundation
import Yniffi

public final class YDocument {
    private let document: YrsDoc
    
    public init() {
        self.document = YrsDoc()
    }
    
    private let someQueue = DispatchQueue(label: "ydoc-queue", qos: .userInitiated)
    
    public func transact<T>(_ changes: @escaping (YrsTransaction) -> (T)) -> T {
        // Note: Most straightforward way for now.
        someQueue.sync {
            let transaction = document.transact()
            defer {
                transaction.free()
            }
            return changes(transaction)
        }
    }
    
    public func getOrCreateText(named: String) -> YText {
        YText(text: document.getText(name: named))
    }
    
    public func getOrCreateArray<T: Codable>(named: String) -> YArray<T> {
        YArray(array: document.getArray(name: named))
    }

    public func getOrCreateMap<T: Codable>(named: String) -> YMap<T> {
        YMap(map: document.getMap(name: named))
    }

    public func diff(txn: YrsTransaction, from state: [UInt8] = []) -> [UInt8] {
        try! document.encodeDiffV1(tx: txn, stateVector: state)
    }
}
