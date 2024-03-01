import Yniffi

/// A type that contains a reference to a document and provides a convenience accessor to interacting with transactions from it.
protocol Transactable {
    /// The document used to coordinate transactions
    var document: YDocument { get }
    /// A convenience accessor to interacting with the shared data types within a document.
    ///
    /// - Parameters:
    ///   - transaction: An optional transaction that, if provided, is passed to the trailing closure. If not provided, a new transaction is requested from the ``YDocument``.
    ///   - changes: A trailing closure that provides the transaction you use to interact with shared types.
    /// - Returns: Returns the returned value from the trailing closure.
    func withTransaction<T>(_ transaction: YrsTransaction?, changes: @escaping (YrsTransaction) -> T) -> T
}

extension Transactable {
    /// A convenience accessor to interacting with the shared data types within a document.
    ///
    /// - Parameters:
    ///   - transaction: An optional transaction that, if provided, is passed to the trailing closure. If not provided, a new transaction is requested from the ``YDocument``.
    ///   - changes: A trailing closure that provides the transaction you use to interact with shared types.
    /// - Returns: Returns the returned value from the trailing closure.
    func withTransaction<T>(_ transaction: YrsTransaction? = nil, changes: @escaping (YrsTransaction) -> T) -> T {
        if let transaction = transaction {
            return changes(transaction)
        } else {
            return document.transactSync(origin: .none, changes)
        }
    }
}
