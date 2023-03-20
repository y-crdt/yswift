import Foundation
import Yniffi

public final class YMap<T: Codable> {
    private let map: YrsMap
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    public init(map: YrsMap) {
        self.map = map
    }
    
    public func insert(tx: YrsTransaction, key: String, value: T) {
        map.insert(tx: tx, key: key, value: encoded(value))
    }
    
    public func length(tx: YrsTransaction) -> Int {
        Int(map.length(tx: tx))
    }

    public func get(tx: YrsTransaction, key: String) -> T {
        decoded(
            try! map.get(tx: tx, key: key)
        )
    }
    
    public func contains_key(tx: YrsTransaction, key: String) -> Bool {
        map.containsKey(tx: tx, key: key)
    }
    
    public func remove(tx: YrsTransaction, key: String) -> T? {
        decoded(
            try! map.remove(tx: tx, key: key)
        )
    }
    
    public func clear(tx: YrsTransaction)  {
        map.clear(tx: tx)
    }

    public func keys(tx: YrsTransaction, _ body: @escaping (String) -> Void) {
        // @TODO: check for memory leaks
        // Wrap the closure that accepts the key (:String) callback for each key
        // found within the map into a reference object to safely pass across
        // the UniFFI language bindings into Rust.
        let delegate = YMapIteratorDelegate(callback: body)
        map.keys(tx: tx, delegate: delegate)
    }

//    public func forEach(tx: YrsTransaction, _ body: @escaping (T) -> Void) {
//        // @TODO: check for memory leaks
//        let delegate = YArrayEachDelegate(callback: body, decoded: decoded)
//        array.each(tx: tx, delegate: delegate)
//    }
    

//    public func observe(_ body: @escaping ([YrsChange]) -> Void) -> UInt32 {
//        let delegate = YArrayObservationDelegate(callback: body)
//        return array.observe(delegate: delegate)
//    }
    
//    public func unobserve(_ subscriptionId: UInt32) {
//        array.unobserve(subscriptionId: subscriptionId)
//    }
    
//    public func toMap(tx: YrsTransaction) -> [T] {
//        decodedMap(map.toA(tx: tx))
//    }
    
    /// Decodes a string value into the appropriate type
    private func decoded(_ stringValue: String) -> T {
        let data = stringValue.data(using: .utf8)!
        return try! decoder.decode(T.self, from: data)
    }

    /// Decodes an optional string value into an optional form of the appropriate type.
    private func decoded(_ stringValue: String?) -> T? {
        if let data = stringValue?.data(using: .utf8)! {
            return try! decoder.decode(T.self, from: data)
        } else {
            return nil
        }
    }

//    private func decodedMap(_ arrayValue: [String]) -> [T] {
//        arrayValue.map {
//            decoded($0)
//        }
//    }
    
    private func encoded(_ value: T) -> String {
        let data = try! encoder.encode(value)
        return String(data: data, encoding: .utf8)!
    }
    
//    private func encodedArray(_ value: [T]) -> [String] {
//        value.map {
//            encoded($0)
//        }
//    }
}

/// A type that holds a closure that the Rust language bindings calls
/// while iterating the keys of a Map.
class YMapIteratorDelegate: YrsMapIteratorDelegate {
    private var callback: (String) -> Void
    
    init(callback: @escaping (String) -> Void) {
        self.callback = callback
    }

    func call(value: String) {
        callback(value)
    }
}

//class YArrayEachDelegate<T: Codable>: YrsArrayEachDelegate {
//    private var callback: (T) -> Void
//    private var decoded: (String) -> T
//
//    init(
//        callback: @escaping (T) -> Void,
//        decoded: @escaping (String) -> T
//    ) {
//        self.callback = callback
//        self.decoded = decoded
//    }
//
//    func call(value: String) {
//        callback(decoded(value))
//    }
//}
