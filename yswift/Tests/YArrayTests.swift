import XCTest
@testable import YSwift

class YArrayTests: XCTestCase {
    func test_insert() {
        let document = YDocument()
        let array: YArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
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
        let array: YArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
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
        let array: YArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
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
        let array: YArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
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
        let array: YArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
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
        let array: YArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
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
        let array: YArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
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
    
    func test_observation() {
        let document = YDocument()
        let array: YArray<SomeType> = document.getOrCreateArray(named: "some_array")
        let decoder = JSONDecoder()

        let insertedElements = [SomeType(name: "Some Dude", age: 24), SomeType(name: "Another Dude", age: 32)]
        var receivedElements: [SomeType] = []
        
        let subscriptionId = array.observe { changes in
            changes.forEach {
                switch $0 {
                case let .added(elements):
                    receivedElements = elements.map {
                        let data = $0.data(using: .utf8)!
                        return try! decoder.decode(SomeType.self, from: data)
                    }
                default: break
                }
            }
        }
        
        document.transact { txn in
            array.insertArray(tx: txn, index: 0, values: insertedElements)
        }
        
        array.unobserve(subscriptionId)
        
        XCTAssertEqual(insertedElements, receivedElements)
    }
    
    /*
     https://www.swiftbysundell.com/articles/using-unit-tests-to-identify-avoid-memory-leaks-in-swift/
     https://alisoftware.github.io/swift/closures/2016/07/25/closure-capture-1/
     */
    
    func test_observationIsLeaking() {
        let document = YDocument()
        let array: YArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
        // Create an object (it can be of any type), and hold both
        // a strong and a weak reference to it
        var object = NSObject()
        weak var weakObject = object
        
        let _ = array.observe { [object] changes in
            // Capture the object in the closure (note that we need to use
            // a capture list like [object] above in order for the object
            // to be captured by reference instead of by pointer value)
            _ = object
            changes.forEach { _ in }
        }
        
        // When we re-assign our local strong reference to a new object the
        // weak reference should still persist.
        // Because we didn't explicitly unobserved/unsubscribed.
        object = NSObject()
        XCTAssertNotNil(weakObject)
    }
    
    func test_observation_IsNotLeaking_afterUnobserving() {
        let document = YDocument()
        let array: YArray<SomeType> = document.getOrCreateArray(named: "some_array")
        
        // Create an object (it can be of any type), and hold both
        // a strong and a weak reference to it
        var object = NSObject()
        weak var weakObject = object
        
        let subscriptionId = array.observe { [object] changes in
            // Capture the object in the closure (note that we need to use
            // a capture list like [object] above in order for the object
            // to be captured by reference instead of by pointer value)
            _ = object
            changes.forEach { _ in }
        }
        
        // Explicit unobserving, to prevent leaking
        array.unobserve(subscriptionId)
        
        // When we re-assign our local strong reference to a new object the
        // weak reference should become nil, since the closure should
        // have been run and removed at this point
        // Because we did explicitly unobserve/unsubscribe at this point.
        object = NSObject()
        XCTAssertNil(weakObject)
    }
}
