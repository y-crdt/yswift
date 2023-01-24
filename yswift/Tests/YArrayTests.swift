import XCTest
@testable import YSwift

struct SomeType: Codable, Equatable {
    let name: String
    let age: Int
}

class YArrayTests: XCTestCase {
    func test_insert() {
        let document = YDocument()
        let array: YYArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
        let initialInstance = SomeType(name: "Aidar", age: 24)
        
        document.transact { txn in
            array.insert(tx: txn, index: 0, value: initialInstance)
        }
        
        let finalInstance = document.transact { txn in
            array.get(tx: txn, index: 0)
        }
        
        XCTAssertEqual(initialInstance, finalInstance)
    }
    
    func test_insertArray() {
        let document = YDocument()
        let array: YYArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
        let arrayToInsert = [SomeType(name: "Some Dude", age: 24), SomeType(name: "Another Dude", age: 32)]
        
        document.transact { txn in
            array.insertArray(tx: txn, index: 0, values: arrayToInsert)
        }
        
        let finalArray = document.transact { txn in
            array.toArray(tx: txn)
        }
        
        XCTAssertEqual(arrayToInsert, finalArray)
    }
    
    func test_length() {
        let document = YDocument()
        let array: YYArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
        let arrayToInsert = [SomeType(name: "Some Dude", age: 24), SomeType(name: "Another Dude", age: 32)]
        
        document.transact { txn in
            array.insertArray(tx: txn, index: 0, values: arrayToInsert)
        }
        
        let length = document.transact { txn in
            array.length(tx: txn)
        }
        
        XCTAssertEqual(length, 2)
    }
    
    func test_pushBack_and_pushFront() {
        let document = YDocument()
        let array: YYArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
        let initialElement = SomeType(name: "I will be in the middle in the end", age: 77)
        let frontElement = SomeType(name: "Some Dude", age: 24)
        let backElement = SomeType(name: "Another Dude", age: 32)
        
        document.transact { txn in
            array.insert(tx: txn, index: 0, value: initialElement)
            array.pushBack(tx: txn, value: backElement)
            array.pushFront(tx: txn, value: frontElement)
        }
        
        let finalArray = document.transact { txn in
            array.toArray(tx: txn)
        }
        
        XCTAssertEqual(finalArray, [frontElement, initialElement, backElement])
    }
    
    func test_remove() {
        let document = YDocument()
        let array: YYArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
        let initialElement = SomeType(name: "I will be in the middle in the end", age: 77)
        let frontElement = SomeType(name: "Some Dude", age: 24)
        let backElement = SomeType(name: "Another Dude", age: 32)
        
        document.transact { txn in
            array.insert(tx: txn, index: 0, value: initialElement)
            array.pushBack(tx: txn, value: backElement)
            array.pushFront(tx: txn, value: frontElement)
        }
        
        document.transact { txn in
            array.remove(tx: txn, index: 1)
        }
        
        let finalArray = document.transact { txn in
            array.toArray(tx: txn)
        }
        
        XCTAssertEqual(finalArray, [frontElement, backElement])
    }
    
    func test_removeRange() {
        let document = YDocument()
        let array: YYArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
        let initialElement = SomeType(name: "I will be in the middle in the end", age: 77)
        let frontElement = SomeType(name: "Some Dude", age: 24)
        let backElement = SomeType(name: "Another Dude", age: 32)
        
        document.transact { txn in
            array.insert(tx: txn, index: 0, value: initialElement)
            array.pushBack(tx: txn, value: backElement)
            array.pushFront(tx: txn, value: frontElement)
        }
        
        document.transact { txn in
            array.removeRange(tx: txn, index: 0, length: 3)
        }
        
        let finalArray = document.transact { txn in
            array.toArray(tx: txn)
        }
        
        XCTAssertEqual(finalArray, [])
    }
    
    func test_forEach() {
        let document = YDocument()
        let array: YYArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
        let arrayToInsert = [SomeType(name: "Some Dude", age: 24), SomeType(name: "Another Dude", age: 32)]
        
        document.transact { txn in
            array.insertArray(tx: txn, index: 0, values: arrayToInsert)
        }
        
        let collectedArray: [SomeType] = document.transact { txn in
            var collectedArray: [SomeType] = []
            array.forEach(tx: txn) {
                collectedArray.append($0)
            }
            return collectedArray
        }
        
        XCTAssertEqual(arrayToInsert, collectedArray)
    }
}
