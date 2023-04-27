import Yniffi

protocol Transactable {
    var document: YDocument { get }
    func withTransaction<T>(_ transaction: YrsTransaction?, changes: @escaping (YrsTransaction) -> T) -> T
}

extension Transactable {
    func withTransaction<T>(_ transaction: YrsTransaction? = nil, changes: @escaping (YrsTransaction) -> T) -> T {
        if let transaction = transaction {
            return changes(transaction)
        } else {
            return document.transactSync(changes)
        }
    }
}


