import Foundation
import Yniffi

// The Swift `Dictionary` methods we'll want to support:
// - var isEmpty: Bool
// - var count: Int
// - var capacity: Int
// - fn subscript(Key) -> Value?
// - fn subscript(Key, default _: () -> Value) -> Value
// - var keys
// - var values
// - updateValue(Value, forKey: Key) -> Value?
// - removeValue(forKey: Key) -> Value?
// - removeAll(keepingCapacity: Bool)

public final class YMap<T: Codable>: Sequence {
    private let docRef: YDocument
    private let map: YrsMap

    public init(map: YrsMap, doc: YDocument) {
        self.docRef = doc
        self.map = map
    }

    public func insert(tx: YrsTransaction, key: String, value: T) {
        map.insert(tx: tx, key: key, value: Coder.encoded(value))
    }

    public func length(tx: YrsTransaction) -> Int {
        Int(map.length(tx: tx))
    }

    public func get(tx: YrsTransaction, key: String) -> T {
        Coder.decoded(
            try! map.get(tx: tx, key: key)
        )
    }

    public func contains_key(tx: YrsTransaction, key: String) -> Bool {
        map.containsKey(tx: tx, key: key)
    }

    @discardableResult
    public func remove(tx: YrsTransaction, key: String) -> T? {
        Coder.decoded(
            try! map.remove(tx: tx, key: key)
        )
    }

    public func clear(tx: YrsTransaction) {
        map.clear(tx: tx)
    }

    public func keys(tx: YrsTransaction, _ body: @escaping (String) -> Void) {
        // @TODO: check for memory leaks
        // Wrap the closure that accepts the key (:String) callback for each key
        // found within the map into a reference object to safely pass across
        // the UniFFI language bindings into Rust.
        let delegate = YMapKeyIteratorDelegate(callback: body)
        map.keys(tx: tx, delegate: delegate)
    }

    public func values(tx: YrsTransaction, _ body: @escaping (T) -> Void) {
        // @TODO: check for memory leaks
        // Wrap the closure that accepts the value (:String) callback for each value
        // found within the map into a reference object to safely pass across
        // the UniFFI language bindings into Rust. The second closure in the delegate
        // is the function that decodes the JSON string into whatever `T` is.
        let delegate = YMapValueIteratorDelegate(callback: body, decoded: Coder.decoded)
        map.values(tx: tx, delegate: delegate)
    }

    public func each(tx: YrsTransaction, _ body: @escaping (String, T) -> Void) {
        // @TODO: check for memory leaks
        // Wrap the closure that accepts both the key and value (:String) callback for every
        // key-value pair within the map into a reference object to safely pass across
        // the UniFFI language bindings into Rust. The second closure in the delegate
        // is the function that decodes the value JSON string into whatever `T` is.
        let delegate = YMapKeyValueIteratorDelegate(callback: body, decoded: Coder.decoded)
        map.each(tx: tx, delegate: delegate)
    }

    public func observe(_ body: @escaping ([YMapChange<T>]) -> Void) -> UInt32 {
        let delegate = YMapObservationDelegate(callback: body, decoded: Coder.decoded)
        return map.observe(delegate: delegate)
    }

    public func unobserve(_ subscriptionId: UInt32) {
        map.unobserve(subscriptionId: subscriptionId)
    }

    public func toMap(tx: YrsTransaction) -> [String: T] {
        var replicatedMap: [String: T] = [:]
        each(tx: tx) { keyValue, typeValue in
            replicatedMap[keyValue] = typeValue
        }
        return replicatedMap
    }

    public typealias Iterator = YMapIterator<T>
    public class YMapIterator<T>: IteratorProtocol {

        var keyList:[String]
        let map: YMap

        init(_ map: YMap) {
            self.map = map
            var tempList:[String] = []
            map.docRef.transact { txn in
                map.keys(tx: txn, { keyValue in
                    tempList.append(keyValue)
                })
            }
            keyList = tempList
        }

        public func next() -> (String, T)? {
            if let key = self.keyList.popLast() {
                let iterSet = self.map.docRef.transact { txn -> (String, T) in
                    let valueForKey: T = self.map.get(tx: txn, key: key) as! T
                    return (key, valueForKey)
                }
                return iterSet
            }
            return nil
        }
    }
    
    // this method can't support the Iterator protocol because I've added
    // YrsTransation to the function, needed for any interactions with the
    // map - but the protocol defines it as taking no additional
    // options. So... where do we get a relevant transaction? Do we stash
    // one within the map, or create it afresh on each iterator creation?
    public func makeIterator() -> YMapIterator<T> {
        YMapIterator(self)
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
        callback: @escaping ([YMapChange<T>]) -> Void,
        decoded: @escaping (String) -> T
    ) {
        self.callback = callback
        self.decoded = decoded
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
