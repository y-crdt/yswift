import Foundation
import Yniffi
import Combine

public final class YArray<T: Codable>: Transactable {
    private let _array: YrsArray
    let document: YDocument

    init(array: YrsArray, document: YDocument) {
        self._array = array
        self.document = document
    }
    
    public var count: Int {
        Int(length())
    }
    
    public var isEmpty: Bool {
        length() == 0
    }

    public func get(index: Int, transaction: YrsTransaction? = nil) -> T? {
        inTransaction(transaction) { txn in
            if let result = try? self._array.get(tx: txn, index: UInt32(index)) {
                return Coder.decoded(result)
            } else {
                return nil
            }
        }
    }

    public func insert(at index: Int, value: T, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.insert(tx: txn, index: UInt32(index), value: Coder.encoded(value))
        }
    }

    public func insertArray(at index: Int, values: [T], transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.insertRange(tx: txn, index: UInt32(index), values: Coder.encodedArray(values))
        }
    }

    public func append(_ value: T, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.pushBack(tx: txn, value: Coder.encoded(value))
        }
    }

    public func prepend(_ value: T, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.pushFront(tx: txn, value: Coder.encoded(value))
        }
    }

    public func remove(at index: Int, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.remove(tx: txn, index: UInt32(index))
        }
    }

    public func removeRange(start: Int, length: Int, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._array.removeRange(tx: txn, index: UInt32(start), len: UInt32(length))
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
    
    public func each(transaction: YrsTransaction? = nil, _ body: @escaping (T) -> Void) {
        let delegate = YArrayEachDelegate(callback: body, decoded: Coder.decoded)
        inTransaction(transaction) { txn in
            self._array.each(tx: txn, delegate: delegate)
        }
    }
    
    public func observe() -> AnyPublisher<[YArrayChange<T>], Never> {
        let subject = PassthroughSubject<[YArrayChange<T>], Never>()
        let subscriptionId = observe { subject.send($0) }
        return subject.handleEvents(receiveCancel: { [weak self] in
            self?._array.unobserve(subscriptionId: subscriptionId)
        })
        .eraseToAnyPublisher()
    }

    public func observe(_ body: @escaping ([YArrayChange<T>]) -> Void) -> UInt32 {
        let delegate = YArrayObservationDelegate(callback: body, decoded: Coder.decodedArray)
        return _array.observe(delegate: delegate)
    }

    public func unobserve(_ subscriptionId: UInt32) {
        _array.unobserve(subscriptionId: subscriptionId)
    }
}

extension YArray: Sequence {
    public typealias Iterator = YArrayIterator
    
    public func makeIterator() -> Iterator {
        YArrayIterator(self)
    }
    
    public class YArrayIterator: IteratorProtocol {
        var array: [T]

        init(_ array: YArray) {
            self.array = array.toArray()
        }
        
        public func next() -> T? {
            array.popLast()
        }
    }
}

// At the moment, below protocol implementations are "stub"-ish in nature
// They need to be completed & tested after Iterator is ported from Rust side
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
            precondition(position < endIndex, "Index out of bounds")
            return self.get(index: position)!
        }
        set(newValue) {
            precondition(position < endIndex, "Index out of bounds")
            inTransaction { txn in
                self.remove(at: position, transaction: txn)
                self.insert(at: position, value: newValue, transaction: txn)
            }
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
