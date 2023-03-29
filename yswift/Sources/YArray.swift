import Foundation
import Yniffi

public final class YArray<T: Codable>: Transactable {
    private let _array: YrsArray
    internal let document: YDocument

    internal init(array: YrsArray, document: YDocument) {
        self._array = array
        self.document = document
    }

    #warning("@TODO: wrap `try` in `do/catch`")
    public func get(index: Int, transaction: YrsTransaction? = nil) -> T {
        inTransaction(transaction) { txn in
            Coder.decoded(try! self._array.get(tx: txn, index: UInt32(index)))
        }
    }

    public func insert(index: Int, value: T, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.insert(tx: txn, index: UInt32(index), value: Coder.encoded(value))
        }
    }

    public func insertArray(index: Int, values: [T], transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.insertRange(tx: txn, index: UInt32(index), values: Coder.encodedArray(values))
        }
    }

    public func pushBack(value: T, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.pushBack(tx: txn, value: Coder.encoded(value))
        }
    }

    public func pushFront(value: T, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.pushFront(tx: txn, value: Coder.encoded(value))
        }
    }

    public func remove(index: Int, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.remove(tx: txn, index: UInt32(index))
        }
    }

    public func removeRange(index: Int, length: Int, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.removeRange(tx: txn, index: UInt32(index), len: UInt32(length))
        }
    }
    
    public func length(transaction: YrsTransaction? = nil) -> UInt32 {
        inTransaction(transaction) { txn in
            self._array.length(tx: txn)
        }
    }
    
    public func toArray(transaction: YrsTransaction? = nil) -> [T] {
        inTransaction(transaction) { txn in
            Coder.decodedArray(self._array.toA(tx: txn))
        }
    }
    
    public func forEach(_ body: @escaping (T) -> Void, transaction: YrsTransaction? = nil) {
        let delegate = YArrayEachDelegate(callback: body, decoded: Coder.decoded)
        inTransaction(transaction) { txn in
            self._array.each(tx: txn, delegate: delegate)
        }
    }

    public func observe(_ body: @escaping ([YrsChange]) -> Void) -> UInt32 {
        let delegate = YArrayObservationDelegate(callback: body)
        return _array.observe(delegate: delegate)
    }

    public func unobserve(_ subscriptionId: UInt32) {
        _array.unobserve(subscriptionId: subscriptionId)
    }
}

class YArrayEachDelegate<T: Codable>: YrsArrayEachDelegate {
    private var callback: (T) -> Void
    private var decoded: (String) -> T

    init(
        callback: @escaping (T) -> Void,
        decoded: @escaping (String) -> T
    ) {
        self.callback = callback
        self.decoded = decoded
    }

    func call(value: String) {
        callback(decoded(value))
    }
}

class YArrayObservationDelegate: YrsArrayObservationDelegate {
    private var callback: ([YrsChange]) -> Void

    init(callback: @escaping ([YrsChange]) -> Void) {
        self.callback = callback
    }

    func call(value: [YrsChange]) {
        callback(value)
    }
}
