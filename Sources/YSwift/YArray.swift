import Combine
import Foundation
import Yniffi

/// A type that provides a list shared data type.
///
/// Store, order, and retrieve any single `Codable` type within a `YArray`.
///
/// Create a new `YArray` instance using ``YSwift/YDocument/getOrCreateArray(named:)`` from a ``YDocument``.
public final class YArray<T: Codable>: Transactable, YCollection {
    private let _array: YrsArray
    let document: YDocument

    init(array: YrsArray, document: YDocument) {
        _array = array
        self.document = document
    }

    /// The length of the list.
    public var count: Int {
        Int(length())
    }

    /// A Boolean value that indicates whether the list is empty.
    public var isEmpty: Bool {
        length() == 0
    }

    /// Returns the object at the index location you provide.
    /// - Parameters:
    ///   - index: The location in the list to retrieve.
    ///   - transaction: An optional transaction to use when retrieving an object.
    /// - Returns: Returns the instance of a Codable type that was stored at the location you provided, or `nil` if it isn't available or couldn't be decoded.
    public func get(index: Int, transaction: YrsTransaction? = nil) -> T? {
        withTransaction(transaction) { txn in
            if let result = try? self._array.get(tx: txn, index: UInt32(index)) {
                return Coder.decoded(result)
            } else {
                return nil
            }
        }
    }

    /// Insert an object at an index location you provide.
    /// - Parameters:
    ///   - index: The location in the list to insert the object.
    ///   - value: The object to insert.
    ///   - transaction: An optional transaction to use when retrieving an object.
    public func insert(at index: Int, value: T, transaction: YrsTransaction? = nil) {
        withTransaction(transaction) { txn in
            self._array.insert(tx: txn, index: UInt32(index), value: Coder.encoded(value))
        }
    }

    /// Inserts an array of objects at the index location you provide.
    /// - Parameters:
    ///   - index: The location in the list to insert the objects.
    ///   - values: An array of objects to insert.
    ///   - transaction: An optional transaction to use when retrieving an object.
    public func insertArray(at index: Int, values: [T], transaction: YrsTransaction? = nil) {
        withTransaction(transaction) { txn in
            self._array.insertRange(tx: txn, index: UInt32(index), values: Coder.encodedArray(values))
        }
    }

    /// Append an object to the end of the list.
    /// - Parameters:
    ///   - value: The object to insert.
    ///   - transaction: An optional transaction to use when retrieving an object.
    public func append(_ value: T, transaction: YrsTransaction? = nil) {
        withTransaction(transaction) { txn in
            self._array.pushBack(tx: txn, value: Coder.encoded(value))
        }
    }

    /// Prepends an object at the beginning of the list.
    /// - Parameters:
    ///   - value: The object to insert.
    ///   - transaction: An optional transaction to use when retrieving an object.
    public func prepend(_ value: T, transaction: YrsTransaction? = nil) {
        withTransaction(transaction) { txn in
            self._array.pushFront(tx: txn, value: Coder.encoded(value))
        }
    }

    /// Remove an object from the list.
    /// - Parameters:
    ///   - index: The index location of the object to remove.
    ///   - transaction: An optional transaction to use when retrieving an object.
    public func remove(at index: Int, transaction: YrsTransaction? = nil) {
        withTransaction(transaction) { txn in
            self._array.remove(tx: txn, index: UInt32(index))
        }
    }

    /// Removes a range of objects from the list, starting at the index position and for the number of elements you provide.
    /// - Parameters:
    ///   - start: The index location of the first object to remove.
    ///   - length: The number of objects to remove.
    ///   - transaction: An optional transaction to use when retrieving an object.
    public func removeRange(start: Int, length: Int, transaction: YrsTransaction? = nil) {
        withTransaction(transaction) { txn in
            self._array.removeRange(tx: txn, index: UInt32(start), len: UInt32(length))
        }
    }

    /// Returns the length of the list.
    /// - Parameter transaction: An optional transaction to use when retrieving an object.
    public func length(transaction: YrsTransaction? = nil) -> UInt32 {
        withTransaction(transaction) { txn in
            self._array.length(tx: txn)
        }
    }

    /// Returns the contents of the list as an array of objects.
    /// - Parameter transaction: An optional transaction to use when retrieving an object.
    public func toArray(transaction: YrsTransaction? = nil) -> [T] {
        withTransaction(transaction) { txn in
            Coder.decodedArray(self._array.toA(tx: txn))
        }
    }

    /// Iterates over the list of elements, providing each element to the closure you provide.
    /// - Parameters:
    ///   - transaction: An optional transaction to use when retrieving an object.
    ///   - body: A closure that is called repeatedly with each element in the list.
    public func each(transaction: YrsTransaction? = nil, _ body: @escaping (T) -> Void) {
        let delegate = YArrayEachDelegate(callback: body, decoded: Coder.decoded)
        withTransaction(transaction) { txn in
            self._array.each(tx: txn, delegate: delegate)
        }
    }

    /// Returns a publisher of array changes.
    public func observe() -> AnyPublisher<[YArrayChange<T>], Never> {
        let subject = PassthroughSubject<[YArrayChange<T>], Never>()
        let subscription = observe { subject.send($0) }
        return subject.handleEvents(receiveCancel: {
            subscription.cancel()
        })
        .eraseToAnyPublisher()
    }

    /// Registers a closure that is called with an array of changes to the list.
    /// - Parameter body: A closure that is called with an array of list changes.
    /// - Returns: An observer identifier.
    public func observe(_ body: @escaping ([YArrayChange<T>]) -> Void) -> YSubscription {
        let delegate = YArrayObservationDelegate(callback: body, decoded: Coder.decodedArray)
        return YSubscription(subscription: _array.observe(delegate: delegate))
    }
    
    public func pointer() -> YrsCollectionPtr {
        return _array.rawPtr()
    }
}

extension YArray: Sequence {
    public typealias Iterator = YArrayIterator

    /// Returns an iterator for the list.
    public func makeIterator() -> Iterator {
        YArrayIterator(self)
    }

    public class YArrayIterator: IteratorProtocol {
        private var indexPosition: Int
        private var arrayRef: YArray

        init(_ arrayRef: YArray) {
            self.arrayRef = arrayRef
            indexPosition = 0
        }

        public func next() -> T? {
            if let item = arrayRef.get(index: indexPosition) {
                indexPosition += 1
                return item
            }
            return nil
        }
    }
}

// At the moment, below protocol implementations are "stub"-ish in nature
// They need to be completed & tested after Iterator is ported from Rust side
extension YArray: MutableCollection, RandomAccessCollection {
    public func index(after i: Int) -> Int {
        // precondition ensures index never goes past the bounds
        precondition(i < endIndex, "Index out of bounds")
        return i + 1
    }

    /// The location of the start of the list.
    public var startIndex: Int {
        0
    }

    /// The location at the end of the list.
    public var endIndex: Int {
        Int(length())
    }

    /// Inserts or returns the object in the list at the position you specify.
    public subscript(position: Int) -> T {
        get {
            precondition(position < endIndex, "Index out of bounds")
            return get(index: position)!
        }
        set(newValue) {
            precondition(position < endIndex, "Index out of bounds")
            withTransaction { txn in
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

/// A type that represents changes to a list.
public enum YArrayChange<T> {
    /// Objects added to the list.
    case added(elements: [T])
    /// An index position that is removed.
    case removed(range: UInt32)
    /// An index position that is updated.
    case retained(range: UInt32)
}

extension YArrayChange: Equatable where T: Equatable {
    public static func == (lhs: YArrayChange<T>, rhs: YArrayChange<T>) -> Bool {
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
