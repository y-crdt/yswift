import XCTest
@testable import YSwift

class YArrayTests: XCTestCase {
    var document: YDocument!
    var array: YArray<TestType>!
    
    override func setUp() {
        document = YDocument()
        array = document.getOrCreateArray(named: "test")
    }
    
    override func tearDown() {
        document = nil
        array = nil
    }
    
    func test_insert() {
        let initialInstance = TestType(name: "Aidar", age: 24)
        
        array.insert(index: 0, value: initialInstance)
        
        XCTAssertEqual(array.get(index: 0), initialInstance)
    }
    
    func test_getIndexOutOfBounds() {
        let initialInstance = TestType(name: "Aidar", age: 24)
        
        array.insert(index: 0, value: initialInstance)
        
        XCTAssertEqual(array.get(index: 1), nil)
    }

    func test_insertArray() {
        let arrayToInsert = [TestType(name: "Aidar", age: 24), TestType(name: "Joe", age: 55)]

        array.insertArray(index: 0, values: arrayToInsert)

        XCTAssertEqual(array.toArray(), arrayToInsert)
    }

    func test_length() {
        array.insert(index: 0, value: TestType(name: "Aidar", age: 24))
        XCTAssertEqual(array.length(), 1)
    }

    func test_pushBack_and_pushFront() {
        let initial = TestType(name: "Middleton", age: 77)
        let front = TestType(name: "Aidar", age: 24)
        let back = TestType(name: "Joe", age: 55)
        
        array.insert(index: 0, value: initial)
        array.pushBack(value: back)
        array.pushFront(value: front)

        XCTAssertEqual(array.toArray(), [front, initial, back])
    }

    func test_remove() {
        let initial = TestType(name: "Middleton", age: 77)
        let front = TestType(name: "Aidar", age: 24)
        let back = TestType(name: "Joe", age: 55)
        
        array.insert(index: 0, value: initial)
        array.pushBack(value: back)
        array.pushFront(value: front)
        
        XCTAssertEqual(array.toArray(), [front, initial, back])

        array.remove(index: 1)

        XCTAssertEqual(array.toArray(), [front, back])
    }

    func test_removeRange() {
        let initial = TestType(name: "Middleton", age: 77)
        let front = TestType(name: "Aidar", age: 24)
        let back = TestType(name: "Joe", age: 55)
        
        array.insert(index: 0, value: initial)
        array.pushBack(value: back)
        array.pushFront(value: front)
        
        XCTAssertEqual(array.toArray(), [front, initial, back])
        
        array.removeRange(index: 0, length: 3)

        XCTAssertEqual(array.length(), 0)
    }

    func test_forEach() {
        let arrayToInsert = [TestType(name: "Aidar", age: 24), TestType(name: "Joe", age: 55)]
        var collectedArray: [TestType] = []

        array.insertArray(index: 0, values: arrayToInsert)

        array.each {
            collectedArray.append($0)
        }
        
        XCTAssertEqual(arrayToInsert, collectedArray)
    }

    func test_observation() {
        let insertedElements = [TestType(name: "Aidar", age: 24), TestType(name: "Joe", age: 55)]
        var receivedElements: [TestType] = []

        let subscriptionId = array.observe { changes in
            changes.forEach {
                switch $0 {
                case let .added(elements):
                    receivedElements = elements
                default: break
                }
            }
        }

        array.insertArray(index: 0, values: insertedElements)

        array.unobserve(subscriptionId)

        XCTAssertEqual(insertedElements, receivedElements)
    }
    
    func test_transaction_IsNotLeaking() {
        let localDocument = YDocument()
        let localArray: YArray<TestType> = localDocument.getOrCreateArray(named: "test")
        
        var object = NSObject()
        weak var weakObject = object
        
        localDocument.transactSync { [object] txn in
            _ = object
            localArray.insert(index: 0, value: .init(name: "Aidar", age: 24), transaction: txn)
        }
        
        object = NSObject()
        XCTAssertNil(weakObject)
        trackForMemoryLeaks(localArray)
        trackForMemoryLeaks(localDocument)
    }

    /*
     https://www.swiftbysundell.com/articles/using-unit-tests-to-identify-avoid-memory-leaks-in-swift/
     https://alisoftware.github.io/swift/closures/2016/07/25/closure-capture-1/
     */

    func test_observation_IsLeaking() {
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
