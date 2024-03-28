import Combine
import Foundation
import Yniffi

/// A type that provides a map shared data type.
///
/// Store, order, and retrieve any single `Codable` type within a `YMap` keyed with a `String`.
///
/// Create a new `YMap` instance using ``YSwift/YDocument/getOrCreateMap(named:)`` from a ``YDocument``.
public final class YMap<T: Codable>: Transactable, YCollection {
    private let _map: YrsMap
    let document: YDocument

    init(map: YrsMap, document: YDocument) {
        _map = map
        self.document = document
    }

    /// Returns a Boolean value that indicates whether the map is empty.
    public var isEmpty: Bool {
        length() == 0
    }

    /// Returns the number of items in the map.
    public var count: Int {
        Int(length())
    }

    /// Gets or sets the value within a map identified by the string you provide.
    public subscript(key: String) -> T? {
        get {
            get(key: key)
        }
        set {
            if let newValue = newValue {
                updateValue(newValue, forKey: key)
            } else {
                removeValue(forKey: key)
            }
        }
    }

    /// Updates or inserts the object for the key you provide.
    /// - Parameters:
    ///   - value: The object to be added into the map.
    ///   - key: The string that identifies the object to be updated.
    ///   - transaction: An optional transaction to use when retrieving an object.
    public func updateValue(_ value: T, forKey key: String, transaction: YrsTransaction? = nil) {
        withTransaction(transaction) { txn in
            self._map.insert(tx: txn, key: key, value: Coder.encoded(value))
        }
    }

    /// Returns the length of the map.
    /// - Parameter transaction: An optional transaction to use when retrieving an object.
    public func length(transaction: YrsTransaction? = nil) -> UInt32 {
        withTransaction(transaction) { txn in
            self._map.length(tx: txn)
        }
    }

    /// Returns the object from the map identified by the key you provide.
    /// - Parameters:
    ///   - key: The string that identifies the object to be retrieved.
    ///   - transaction: An optional transaction to use when retrieving an object.
    /// - Returns: The object within the map at that key, or `nil` if it's not available.
    public func get(key: String, transaction: YrsTransaction? = nil) -> T? {
        withTransaction(transaction) { txn -> T? in
            if let result = try? self._map.get(tx: txn, key: key) {
                return Coder.decoded(result)
            } else {
                return nil
            }
        }
    }

    /// Returns a Boolean value indicating whether the key you provide is in the map.
    /// - Parameters:
    ///   - key: A string that identifies an object within the map.
    ///   - transaction: An optional transaction to use when retrieving an object.
    public func containsKey(_ key: String, transaction: YrsTransaction? = nil) -> Bool {
        withTransaction(transaction) { txn in
            self._map.containsKey(tx: txn, key: key)
        }
    }

    /// Removes an object from the map.
    /// - Parameters:
    ///   - key: A string that identifies the object to remove.
    ///   - transaction: An optional transaction to use when retrieving an object.
    /// - Returns: The item removed, or `nil` if unavailable.
    @discardableResult
    public func removeValue(forKey key: String, transaction: YrsTransaction? = nil) -> T? {
        withTransaction(transaction) { txn -> T? in
            if let result = try? self._map.remove(tx: txn, key: key) {
                return Coder.decoded(result)
            } else {
                return nil
            }
        }
    }

    /// Removes all items from the map.
    /// - Parameter transaction: An optional transaction to use when retrieving an object.
    public func removeAll(transaction: YrsTransaction? = nil) {
        withTransaction(transaction) { txn in
            self._map.clear(tx: txn)
        }
    }

    /// Calls the closure you provide with each key from the map.
    /// - Parameters:
    ///   - transaction: An optional transaction to use when retrieving an object.
    ///   - body: A closure that is called repeatedly with each key in the map.
    public func keys(transaction: YrsTransaction? = nil, _ body: @escaping (String) -> Void) {
        // Wrap the closure that accepts the key (:String) callback for each key
        // found within the map into a reference object to safely pass across
        // the UniFFI language bindings into Rust.
        let delegate = YMapKeyIteratorDelegate(callback: body)
        withTransaction(transaction) { txn in
            self._map.keys(tx: txn, delegate: delegate)
        }
    }

    /// Calls the closure you provide with each value from the map.
    /// - Parameters:
    ///   - transaction: An optional transaction to use when retrieving an object.
    ///   - body: A closure that is called repeatedly with each value in the map.
    public func values(transaction: YrsTransaction? = nil, _ body: @escaping (T) -> Void) {
        // Wrap the closure that accepts the value (:String) callback for each value
        // found within the map into a reference object to safely pass across
        // the UniFFI language bindings into Rust. The second closure in the delegate
        // is the function that decodes the JSON string into whatever `T` is.
        let delegate = YMapValueIteratorDelegate(callback: body, decoded: Coder.decoded)
        withTransaction(transaction) { txn in
            self._map.values(tx: txn, delegate: delegate)
        }
    }

    /// Iterates over the map of elements, providing each element to the closure you provide.
    /// - Parameters:
    ///   - transaction: An optional transaction to use when retrieving an object.
    ///   - body: A closure that is called repeatedly with each element in the map.
    public func each(transaction: YrsTransaction? = nil, _ body: @escaping (String, T) -> Void) {
        // Wrap the closure that accepts both the key and value (:String) callback for every
        // key-value pair within the map into a reference object to safely pass across
        // the UniFFI language bindings into Rust. The second closure in the delegate
        // is the function that decodes the value JSON string into whatever `T` is.
        let delegate = YMapKeyValueIteratorDelegate(callback: body, decoded: Coder.decoded)
        withTransaction(transaction) { txn in
            self._map.each(tx: txn, delegate: delegate)
        }
    }

    /// Returns a publisher of map changes.
    public func observe() -> AnyPublisher<[YMapChange<T>], Never> {
        let subject = PassthroughSubject<[YMapChange<T>], Never>()
        let subscription = observe { subject.send($0) }
        return subject.handleEvents(receiveCancel: {
            subscription.cancel()
        })
        .eraseToAnyPublisher()
    }

    /// Registers a closure that is called with an array of changes to the map.
    /// - Parameter body: A closure that is called with an array of map changes.
    /// - Returns: An observer identifier.
    public func observe(_ body: @escaping ([YMapChange<T>]) -> Void) -> YSubscription {
        let delegate = YMapObservationDelegate(decoded: Coder.decoded, callback: body)
        return YSubscription(subscription: _map.observe(delegate: delegate))
    }

    public func toMap(transaction: YrsTransaction? = nil) -> [String: T] {
        var replicatedMap: [String: T] = [:]
        each(transaction: transaction) { key, value in
            replicatedMap[key] = value
        }
        return replicatedMap
    }
    
    public func pointer() -> YrsCollectionPtr {
        return _map.rawPtr()
    }
}

extension YMap: Sequence {
    public typealias Iterator = YMapIterator

    // this method can't support the Iterator protocol because I've added
    // YrsTransation to the function, needed for any interactions with the
    // map - but the protocol defines it as taking no additional
    // options. So... where do we get a relevant transaction? Do we stash
    // one within the map, or create it afresh on each iterator creation?
    public func makeIterator() -> Iterator {
        YMapIterator(self)
    }

    public class YMapIterator: IteratorProtocol {
        var keyValues: [(String, T)]

        init(_ map: YMap) {
            var collectedKeyValues: [(String, T)] = []
            map.each { key, value in
                collectedKeyValues.append((key, value))
            }
            keyValues = collectedKeyValues
        }

        public func next() -> (String, T)? {
            keyValues.popLast()
        }
    }
}

/// A type that holds a closure that the Rust language bindings calls
/// while iterating the keys of a Map.
class YMapKeyIteratorDelegate: YrsMapIteratorDelegate {
    private var callback: (String) -> Void

    init(callback: @escaping (String) -> Void) {
        self.callback = callback
    }

    func call(value: String) {
        callback(value)
    }
}

/// A type that holds a closure that the Rust language bindings calls
/// while iterating the values of a Map.
///
/// The values returned by Rust is a String with a JSON encoded object that this
/// delegate needs to unwrap/decode on the fly...
class YMapValueIteratorDelegate<T: Codable>: YrsMapIteratorDelegate {
    private var callback: (T) -> Void
    private var decoded: (String) -> T

    init(callback: @escaping (T) -> Void,
         decoded: @escaping (String) -> T)
    {
        self.callback = callback
        self.decoded = decoded
    }

    func call(value: String) {
        callback(decoded(value))
    }
}

/// A type that holds a closure that the Rust language bindings calls
/// while iterating the keys and values of a Map.
///
/// The key is a string, and the value is a String with a JSON encoded object that this
/// delegate needs to unwrap/decode on the fly.
class YMapKeyValueIteratorDelegate<T: Codable>: YrsMapKvIteratorDelegate {
    private var callback: (String, T) -> Void
    private var decoded: (String) -> T

    init(callback: @escaping (String, T) -> Void,
         decoded: @escaping (String) -> T)
    {
        self.callback = callback
        self.decoded = decoded
    }

    func call(key: String, value: String) {
        callback(key, decoded(value))
    }
}

class YMapObservationDelegate<T: Codable>: YrsMapObservationDelegate {
    private var callback: ([YMapChange<T>]) -> Void
    private var decoded: (String) -> T

    init(
        decoded: @escaping (String) -> T,
        callback: @escaping ([YMapChange<T>]) -> Void
    ) {
        self.decoded = decoded
        self.callback = callback
    }

    func call(value: [YrsMapChange]) {
        let result: [YMapChange<T>] = value.map { rsChange -> YMapChange<T> in
            switch rsChange.change {
            case let .inserted(value):
                return YMapChange.inserted(key: rsChange.key, value: decoded(value))
            case let .updated(oldValue, newValue):
                return YMapChange.updated(key: rsChange.key, oldValue: decoded(oldValue), newValue: decoded(newValue))
            case let .removed(value):
                return YMapChange.removed(key: rsChange.key, value: decoded(value))
            }
        }
        callback(result)
    }
}

/// A type that represents changes to a Map.
public enum YMapChange<T> {
    /// The key and value inserted into the map.
    case inserted(key: String, value: T)
    /// The key, old value, and new value updated in the map.
    case updated(key: String, oldValue: T, newValue: T)
    /// The key and value removed from the map.
    case removed(key: String, value: T)
}

extension YMapChange: Equatable where T: Equatable {
    public static func == (lhs: YMapChange<T>, rhs: YMapChange<T>) -> Bool {
        switch (lhs, rhs) {
        case let (.inserted(key1, value1), .inserted(key2, value2)):
            return key1 == key2 && value1 == value2
        case let (.updated(key1, oldValue1, newValue1), .updated(key2, oldValue2, newValue2)):
            return key1 == key2 && oldValue1 == oldValue2 && newValue1 == newValue2
        case let (.removed(key1, value1), .removed(key2, value2)):
            return key1 == key2 && value1 == value2
        default:
            return false
        }
    }
}

extension YMapChange: Hashable where T: Hashable {}
