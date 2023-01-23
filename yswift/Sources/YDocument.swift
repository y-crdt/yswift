import Foundation
import YNativeFinal

public final class YDocument {
    private let document: Doc
    
    public init() {
        self.document = Doc()
    }
    
    public func transact<T>(_ changes: @escaping (Transaction) -> (T)) -> T {
        let transaction = document.transact()
        defer {
            transaction.free()
        }
        return changes(transaction)
    }
    
    public func getOrCreateText(named: String) -> Text {
        document.getText(name: named)
    }
    
    public func getOrCreateArray(named: String) -> YArray {
        document.getArray(name: named)
    }
    
    public func diff(txn: Transaction, from state: [UInt8] = []) -> [UInt8] {
        try! document.encodeDiffV1(tx: txn, stateVector: state)
    }
}
