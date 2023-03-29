import Foundation

final class Coder {
    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    static func encoded<T: Encodable>(_ value: T) -> String {
        let data = try! encoder.encode(value)
        return String(data: data, encoding: .utf8)!
    }

    static func encodedDictionary<T: Encodable>(_ value: [String: T]) -> [String: String] {
        Dictionary(uniqueKeysWithValues: value.map { ($0, encoded($1)) })
    }
    
    static  func encodedArray<T: Encodable>(_ value: [T]) -> [String] {
        value.map {
            encoded($0)
        }
    }
    
    static func decoded<T: Decodable>(_ stringValue: String) -> T {
        let data = stringValue.data(using: .utf8)!
        return try! decoder.decode(T.self, from: data)
    }
    
    static func decoded<T: Decodable>(_ stringValue: String?) -> T? {
        if let data = stringValue?.data(using: .utf8)! {
            return try! decoder.decode(T.self, from: data)
        } else {
            return nil
        }
    }

    static  func decodedArray<T: Decodable>(_ arrayValue: [String]) -> [T] {
        arrayValue.map {
            decoded($0)
        }
    }
}
