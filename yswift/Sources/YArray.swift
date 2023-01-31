import Foundation
import Yniffi

public final class YArray<T: Codable> {
    private let array: YrsArray
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    public init(array: YrsArray) {
        self.array = array
    }
    
    public func forEach(tx: YrsTransaction, _ body: @escaping (T) -> Void) {
        // @TODO: check for memory leaks
        let delegate = YArrayEachDelegate(callback: body, decoded: decoded)
        array.each(tx: tx, delegate: delegate)
    }
    
    public func get(tx: YrsTransaction, index: Int) -> T {
        decoded(
            try! array.get(tx: tx, index: UInt32(index))
        )
    }
    
    public func insert(tx: YrsTransaction, index: Int, value: T) {
        array.insert(tx: tx, index: UInt32(index), value: encoded(value))
    }
    
    public func insertArray(tx: YrsTransaction, index: Int, values: [T]) {
        array.insertRange(tx: tx, index: UInt32(index), values: encodedArray(values))
    }
    
    public func length(tx: YrsTransaction) -> Int {
        Int(array.length(tx: tx))
    }
    
    public func pushBack(tx: YrsTransaction, value: T) {
        array.pushBack(tx: tx, value: encoded(value))
    }
    
    public func pushFront(tx: YrsTransaction, value: T) {
        array.pushFront(tx: tx, value: encoded(value))
    }
    
    public func remove(tx: YrsTransaction, index: Int) {
        array.remove(tx: tx, index: UInt32(index))
    }
    
    public func removeRange(tx: YrsTransaction, index: Int, length: Int) {
        array.removeRange(tx: tx, index: UInt32(index), len: UInt32(length))
    }
    
    public func observe(_ body: @escaping ([YrsChange]) -> Void) -> UInt32 {
        let delegate = YArrayObservationDelegate(callback: body)
        return array.observe(delegate: delegate)
    }
    
    public func unobserve(_ subscriptionId: UInt32) {
        array.unobserve(subscriptionId: subscriptionId)
    }
    
    public func toArray(tx: YrsTransaction) -> [T] {
        decodedArray(array.toA(tx: tx))
    }
    
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
