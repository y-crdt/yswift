import Foundation
import Yniffi
import Combine

public final class YMap<T: Codable>: Transactable {
    private let _map: YrsMap
    let document: YDocument

    init(map: YrsMap, document: YDocument) {
        self._map = map
        self.document = document
    }
    
    public var isEmpty: Bool {
        length() == 0
    }
    
    public var count: Int {
        Int(length())
    }
    
    public subscript (key: String) -> T? {
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
    
    public func updateValue(_ value: T, forKey key: String, transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._map.insert(tx: txn, key: key, value: Coder.encoded(value))
        }
    }

    public func length(transaction: YrsTransaction? = nil) -> UInt32 {
        inTransaction(transaction) { txn in
            self._map.length(tx: txn)
        }
    }

    public func get(key: String, transaction: YrsTransaction? = nil) -> T? {
        inTransaction(transaction) { txn -> T? in
            if let result = try? self._map.get(tx: txn, key: key) {
                return Coder.decoded(result)
            } else {
                return nil
            }
        }
    }

    public func containsKey(_ key: String, transaction: YrsTransaction? = nil) -> Bool {
        inTransaction(transaction) { txn in
            self._map.containsKey(tx: txn, key: key)
        }
    }

    @discardableResult
    public func removeValue(forKey key: String, transaction: YrsTransaction? = nil) -> T? {
        inTransaction(transaction) { txn -> T? in
            if let result = try? self._map.remove(tx: txn, key: key) {
                return Coder.decoded(result)
            } else {
                return nil
            }
        }
    }

    public func removeAll(transaction: YrsTransaction? = nil) {
        inTransaction(transaction) { txn in
            self._map.clear(tx: txn)
        }
    }

    public func keys(transaction: YrsTransaction? = nil, _ body: @escaping (String) -> Void) {
        // Wrap the closure that accepts the key (:String) callback for each key
        // found within the map into a reference object to safely pass across
        // the UniFFI language bindings into Rust.
        let delegate = YMapKeyIteratorDelegate(callback: body)
        inTransaction(transaction) { txn in
            self._map.keys(tx: txn, delegate: delegate)
        }
    }

    public func values(transaction: YrsTransaction? = nil, _ body: @escaping (T) -> Void) {
        // Wrap the closure that accepts the value (:String) callback for each value
        // found within the map into a reference object to safely pass across
        // the UniFFI language bindings into Rust. The second closure in the delegate
        // is the function that decodes the JSON string into whatever `T` is.
        let delegate = YMapValueIteratorDelegate(callback: body, decoded: Coder.decoded)
        inTransaction(transaction) { txn in
            self._map.values(tx: txn, delegate: delegate)
        }
    }

    public func each(transaction: YrsTransaction? = nil, _ body: @escaping (String, T) -> Void) {
        // Wrap the closure that accepts both the key and value (:String) callback for every
        // key-value pair within the map into a reference object to safely pass across
        // the UniFFI language bindings into Rust. The second closure in the delegate
        // is the function that decodes the value JSON string into whatever `T` is.
        let delegate = YMapKeyValueIteratorDelegate(callback: body, decoded: Coder.decoded)
        inTransaction(transaction) { txn in
            self._map.each(tx: txn, delegate: delegate)
        }
    }
    
    public func observe() -> AnyPublisher<[YMapChange<T>], Never> {
        let subject = PassthroughSubject<[YMapChange<T>], Never>()
        let subscriptionId = observe { subject.send($0) }
        return subject.handleEvents(receiveCancel: { [weak self] in
            self?._map.unobserve(subscriptionId: subscriptionId)
        })
        .eraseToAnyPublisher()
    }

    public func observe(_ body: @escaping ([YMapChange<T>]) -> Void) -> UInt32 {
        let delegate = YMapObservationDelegate(decoded: Coder.decoded, callback: body)
        return _map.observe(delegate: delegate)
    }

    public func unobserve(_ subscriptionId: UInt32) {
        _map.unobserve(subscriptionId: subscriptionId)
    }

    public func toMap(transaction: YrsTransaction? = nil) -> [String: T] {
        var replicatedMap: [String: T] = [:]
        each(transaction: transaction) { key, value in
            replicatedMap[key] = value
        }
        return replicatedMap
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

public enum YMapChange<T> {
    case inserted(key: String, value: T)
    case updated(key: String, oldValue: T, newValue: T)
    case removed(key: String, value: T)
}

extension YMapChange: Equatable where T: Equatable {
    public static func ==(lhs: YMapChange<T>, rhs: YMapChange<T>) -> Bool {
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
