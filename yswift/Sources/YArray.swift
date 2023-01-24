import Foundation
import YNativeFinal

public final class YYArray<T: Codable> {
    private let array: YArray
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    init(array: YArray) {
        self.array = array
    }
    
    public func get(tx: Transaction, index: Int) -> T {
        decoded(
            try! array.get(tx: tx, index: UInt32(index))
        )
    }
    
    public func insert(tx: Transaction, index: Int, value: T) {
        array.insert(tx: tx, index: UInt32(index), value: encoded(value))
    }
    
    public func insertArray(tx: Transaction, index: Int, values: [T]) {
        array.insertRange(tx: tx, index: UInt32(index), values: encodedArray(values))
    }
    
    public func length(tx: Transaction) -> Int {
        Int(array.length(tx: tx))
    }
    
    public func pushBack(tx: Transaction, value: T) {
        array.pushBack(tx: tx, value: encoded(value))
    }
    
    public func pushFront(tx: Transaction, value: T) {
        array.pushFront(tx: tx, value: encoded(value))
    }
    
    public func remove(tx: Transaction, index: Int) {
        array.remove(tx: tx, index: UInt32(index))
    }
    
    public func removeRange(tx: Transaction, index: Int, length: Int) {
        array.removeRange(tx: tx, index: UInt32(index), len: UInt32(length))
    }
    
    public func toArray(tx: Transaction) -> [T] {
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
