import Foundation
import Yniffi

public final class YMap<T: Codable> {
    private let map: YrsMap
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    public init(map: YrsMap) {
        self.map = map
    }
    
//    public func forEach(tx: YrsTransaction, _ body: @escaping (T) -> Void) {
//        // @TODO: check for memory leaks
//        let delegate = YArrayEachDelegate(callback: body, decoded: decoded)
//        array.each(tx: tx, delegate: delegate)
//    }
    
    public func insert(tx: YrsTransaction, key: String, value: T) {
        map.insert(tx: tx, key: key, value: encoded(value))
    }
    
//    public func insertArray(tx: YrsTransaction, index: Int, values: [T]) {
//        array.insertRange(tx: tx, index: UInt32(index), values: encodedArray(values))
//    }
    
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
