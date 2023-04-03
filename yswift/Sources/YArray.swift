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

    public func observe(_ body: @escaping ([YArrayChange<T>]) -> Void) -> UInt32 {
        let delegate = YArrayObservationDelegate(callback: body, decoded: Coder.decodedArray)
        return _array.observe(delegate: delegate)
    }

    public func unobserve(_ subscriptionId: UInt32) {
        _array.unobserve(subscriptionId: subscriptionId)
    }
}

extension YArray: MutableCollection, RandomAccessCollection {
    public func index(after i: Int) -> Int {
        // precondition ensures index nevers goes past
        precondition(i < endIndex, "Index out of bounds")
        return i + 1
    }
    
    public var startIndex: Int {
        0
    }
    
    public var endIndex: Int {
        Int(self.length())
    }
    
    public subscript(position: Int) -> T {
        get {
            self.get(index: position)
        }
        set(newValue) {
            inTransaction { txn in
                self.remove(index: position, transaction: txn)
                self.insert(index: position, value: newValue)
            }
        }
    }
    
    public func makeIterator() -> YArrayIterator<T> {
        YArrayIterator()
    }
}

public final class YArrayIterator<T: Codable>: IteratorProtocol {
    public typealias Element = T
    
    public func next() -> T? {
        nil
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

class YArrayObservationDelegate<T: Codable>: YrsArrayObservationDelegate {
    private var callback: ([YArrayChange<T>]) -> Void
    private var decoded: ([String]) -> [T]

    init(
        callback: @escaping ([YArrayChange<T>]) -> Void,
        decoded: @escaping ([String]) -> [T]
    ) {
        self.callback = callback
        self.decoded = decoded
    }

    func call(value: [YrsChange]) {
        let result: [YArrayChange<T>] = value.map { rsChange -> YArrayChange<T> in
            switch rsChange {
            case let .added(elements):
                return YArrayChange.added(elements: decoded(elements))
            case let .removed(range):
                return YArrayChange.removed(range: range)
            case let .retained(range):
                return YArrayChange.retained(range: range)
            }
        }
        callback(result)
    }
}

public enum YArrayChange<T> {
    case added(elements: [T])
    case removed(range: UInt32)
    case retained(range: UInt32)
}

extension YArrayChange: Equatable where T: Equatable {
    public static func ==(lhs: YArrayChange<T>, rhs: YArrayChange<T>) -> Bool {
        switch (lhs, rhs) {
        case let (.added(elements1), .added(elements2)):
            return elements1 == elements2
        case let (.removed(range1), .removed(range2)):
            return range1 == range2
        case let (.retained(range1), .retained(range2)):
            return range1 == range2
        default:
            return false
        }
    }
}

extension YArrayChange: Hashable where T: Hashable {}
