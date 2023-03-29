import Foundation
import Yniffi

public final class YArray<T: Codable>: Transactable {
    private let _array: YrsArray
    internal let document: YDocument

    internal init(array: YrsArray, document: YDocument) {
        self._array = array
        self.document = document
    }

    public func get(index: Int, transaction: YrsTransaction? = nil) -> T {
        inTransaction(transaction) { txn in
            self.decoded(try! self._array.get(tx: txn, index: UInt32(index)))
        }
    }

    public func insert(index: Int, value: T, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.insert(tx: txn, index: UInt32(index), value: self.encoded(value))
        }
    }

    public func insertArray(index: Int, values: [T], transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.insertRange(tx: txn, index: UInt32(index), values: self.encodedArray(values))
        }
    }

    public func pushBack(value: T, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.pushBack(tx: txn, value: self.encoded(value))
        }
    }

    public func pushFront(value: T, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.pushFront(tx: txn, value: self.encoded(value))
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
            self.decodedArray(self._array.toA(tx: txn))
        }
    }
    
    public func forEach(_ body: @escaping (T) -> Void, transaction: YrsTransaction? = nil) {
        let delegate = YArrayEachDelegate(callback: body, decoded: decoded)
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
    
    // MARK: - Encoding/Decoding
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private func decoded(_ stringValue: String) -> T {
        let data = stringValue.data(using: .utf8)!
        return try! decoder.decode(T.self, from: data)
    }

    private func decodedArray(_ arrayValue: [String]) -> [T] {
        arrayValue.map {
            decoded($0)
        }
    }

    private func encoded(_ value: T) -> String {
        let data = try! encoder.encode(value)
        return String(data: data, encoding: .utf8)!
    }

    private func encodedArray(_ value: [T]) -> [String] {
        value.map {
            encoded($0)
        }
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
