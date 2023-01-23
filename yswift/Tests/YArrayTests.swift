import XCTest
import YNativeFinal
@testable import YSwift

struct SomeType: Codable, Equatable {
  let name: String
  let age: Int
}

class YArrayTests: XCTestCase {
    func test_insert() {
        let document = YDocument()
        let array = document.getOrCreateArray(named: "some_array")
        
        let initialInstance = SomeType(name: "Aidar", age: 24)
        let encoder = JSONEncoder()
        let encodedData = try! encoder.encode(initialInstance)
        let initialJsonString = String(data: encodedData, encoding: .utf8)!
        
        document.transact { txn in
            array.insert(tx: txn, index: 0, json: initialJsonString)
        }
        
        let finalJsonString = document.transact { txn in
            try! array.get(tx: txn, index: 0)
        }
        
        let decoder = JSONDecoder()
        let decodedData = finalJsonString.data(using: .utf8)!
        let finalInstance = try! decoder.decode(SomeType.self, from: decodedData)
        
        XCTAssertEqual(initialInstance, finalInstance)
    }
}
