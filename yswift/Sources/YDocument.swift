import Foundation
import YNativeFinal

final class YDocument {
    private let document: Doc
    
    init() {
        self.document = Doc()
    }
    
    func transact<T>(_ changes: @escaping (Transaction) -> (T)) -> T {
        let transaction = document.transact()
        defer {
            transaction.free()
        }
        return changes(transaction)
    }
    
    func getOrCreateText(named: String) -> Text {
        document.getText(name: named)
    }
    
    func diff(txn: Transaction, from state: [UInt8] = []) -> [UInt8] {
        try! document.encodeDiffV1(tx: txn, stateVector: state)
    }
}
