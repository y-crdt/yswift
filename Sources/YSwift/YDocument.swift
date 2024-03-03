import Foundation
import Yniffi

/// YDocument holds YSwift shared data types and coordinates collaboration and changes.
public final class YDocument {
    private let document: YrsDoc
    /// Multiple `YDocument` instances are supported. Because `label` is required only for debugging purposes.
    /// It is not used for unique differentiation between queues. So we safely get unique queue for each `YDocument` instance.
    private let transactionQueue = DispatchQueue(label: "YSwift.YDocument", qos: .userInitiated)

    /// Create a new YSwift Document.
    public init() {
        document = YrsDoc()
    }

    /// Compares the state vector from another YSwift document to return a data buffer you can use to synchronize with another YSwift document.
    ///
    /// Use `transactionStateVector()` on a transaction to get a state buffer to compare with this method.
    ///
    /// - Parameters:
    ///   - txn: A transaction within which to compare the state of the document.
    ///   - state: A data buffer from another YSwift document.
    /// - Returns: A buffer that contains the diff you can use to synchronize another YSwift document.
    public func diff(txn: YrsTransaction, from state: [UInt8] = []) -> [UInt8] {
        try! document.encodeDiffV1(tx: txn, stateVector: state)
    }

    // MARK: - Transaction methods

    /// Creates a synchronous transaction and provides that transaction to a trailing closure, within which you make changes to shared data types.
    /// - Parameter changes: The closure in which you make changes to the document.
    /// - Returns: The value that you return from the closure.
    public func transactSync<T>(origin: Origin? = nil, _ changes: @escaping (YrsTransaction) -> T) -> T {
        // Avoiding deadlocks & thread explosion. We do not allow re-entrancy in Transaction methods.
        // It is a programmer's error to invoke synchronous transact from within transaction.
        // Better approach would be to leverage something like `DispatchSpecificKey` in Watchdog style implementation
        // Reference: https://github.com/groue/GRDB.swift/blob/master/GRDB/Core/SchedulingWatchdog.swift
        dispatchPrecondition(condition: .notOnQueue(transactionQueue))
        return transactionQueue.sync {
            let transaction = document.transact(origin: origin?.origin)
            defer {
                transaction.free()
            }
            return changes(transaction)
        }
    }

    /// Creates an asynchronous transaction and provides that transaction to a trailing closure, within which you make changes to shared data types.
    /// - Parameter changes: The closure in which you make changes to the document.
    /// - Returns: The value that you return from the closure.
    public func transact<T>(origin: Origin? = nil, _ changes: @escaping (YrsTransaction) -> T) async -> T {
        await withCheckedContinuation { continuation in
            transactAsync(origin, changes) { result in
                continuation.resume(returning: result)
            }
        }
    }

    /// Creates an asynchronous transaction and provides that transaction to a trailing closure, within which you make changes to shared data types.
    /// - Parameter changes: The closure in which you make changes to the document.
    /// - Parameter completion: A completion handler that is called with the value returned from the closure in which you made changes.
    public func transactAsync<T>(_ origin: Origin? = nil, _ changes: @escaping (YrsTransaction) -> T, completion: @escaping (T) -> Void) {
        transactionQueue.async { [weak self] in
            guard let self = self else { return }
            let transaction = self.document.transact(origin: origin?.origin)
            defer {
                transaction.free()
            }
            let result = changes(transaction)
            completion(result)
        }
    }

    // MARK: - Factory methods

    /// Retrieves or creates a Text shared data type.
    /// - Parameter named: The key you use to reference the Text shared data type.
    /// - Returns: The text shared type.
    public func getOrCreateText(named: String) -> YText {
        YText(text: document.getText(name: named), document: self)
    }

    /// Retrieves or creates an Array shared data type.
    /// - Parameter named: The key you use to reference the Array shared data type.
    /// - Returns: The array shared type.
    public func getOrCreateArray<T: Codable>(named: String) -> YArray<T> {
        YArray(array: document.getArray(name: named), document: self)
    }

    /// Retrieves or creates a Map shared data type.
    /// - Parameter named: The key you use to reference the Map shared data type.
    /// - Returns: The map shared type.
    public func getOrCreateMap<T: Codable>(named: String) -> YMap<T> {
        YMap(map: document.getMap(name: named), document: self)
    }
    
    public func undoManager<T: AnyObject>(trackedRefs: [YCollection]) -> YUndoManager<T> {
        let mapped = trackedRefs.map({$0.pointer()})
        return YUndoManager(manager: self.document.undoManager(trackedRefs: mapped))
    }
}
