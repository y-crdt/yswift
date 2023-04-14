import XCTest
import Combine
@testable import YSwift

final class YMapTests: XCTestCase {
    var document: YDocument!
    var map: YMap<TestType>!
    
    override func setUp() {
        document = YDocument()
        map = document.getOrCreateMap(named: "test")
    }
    
    override func tearDown() {
        document = nil
        map = nil
    }
    
    func test_insert() {
        let initialInstance = TestType(name: "Aidar", age: 24)
        let secondInstance = TestType(name: "Joe", age: 55)
        
        XCTAssertEqual(map.length(), 0)
        map[initialInstance.name] = initialInstance
        map[secondInstance.name] = secondInstance
        XCTAssertEqual(map.length(), 2)

        let finalInstance = map.get(key: initialInstance.name)
        
        XCTAssertEqual(initialInstance, finalInstance)

        let contains = map.containsKey(secondInstance.name)
        XCTAssertTrue(contains)
    }

    func test_remove() {
        let initialInstance = TestType(name: "Aidar", age: 24)
        let secondInstance = TestType(name: "Joe", age: 55)

        XCTAssertEqual(map.length(), 0)
        map[initialInstance.name] = initialInstance
        map[secondInstance.name] = secondInstance

        XCTAssertEqual(map.length(), 2)
        map.removeValue(forKey: secondInstance.name)
        XCTAssertEqual(map.length(), 1)
    }

    func test_removeAll() {
        let initialInstance = TestType(name: "Aidar", age: 24)
        let secondInstance = TestType(name: "Joe", age: 55)

        XCTAssertEqual(map.length(), 0)
        map[initialInstance.name] = initialInstance
        map[secondInstance.name] = secondInstance

        XCTAssertEqual(map.length(), 2)
        map.removeAll()
        XCTAssertEqual(map.length(), 0)
    }

    func test_keys() {
        let initialInstance = TestType(name: "Aidar", age: 24)
        let secondInstance = TestType(name: "Joe", age: 55)

        XCTAssertEqual(map.length(), 0)
        map[initialInstance.name] = initialInstance
        map[secondInstance.name] = secondInstance
        XCTAssertEqual(map.length(), 2)

        var collectedKeys: [String] = []
        map.keys { collectedKeys.append($0) }

        XCTAssertEqual(collectedKeys.sorted(), ["Aidar", "Joe"])
    }

    func test_values() {
        let initialInstance = TestType(name: "Aidar", age: 24)
        let secondInstance = TestType(name: "Joe", age: 55)

        XCTAssertEqual(map.length(), 0)
        map[initialInstance.name] = initialInstance
        map[secondInstance.name] = secondInstance
        XCTAssertEqual(map.length(), 2)

        var collectedValues: [TestType] = []
        map.values {
            collectedValues.append($0)
        }

        XCTAssertTrue(collectedValues.contains(initialInstance))
        XCTAssertTrue(collectedValues.contains(secondInstance))
    }

    func test_each() {
        let initialInstance = TestType(name: "Aidar", age: 24)
        let secondInstance = TestType(name: "Joe", age: 55)

        XCTAssertEqual(map.length(), 0)
        map[initialInstance.name] = initialInstance
        map[secondInstance.name] = secondInstance
        XCTAssertEqual(map.length(), 2)

        var collectedValues: [String: TestType] = [:]
        map.each { key, value in
            collectedValues[key] = value
        }

        XCTAssertTrue(collectedValues.keys.contains("Aidar"))
        XCTAssertTrue(collectedValues.keys.contains("Joe"))

        XCTAssertTrue(collectedValues.values.contains(initialInstance))
        XCTAssertTrue(collectedValues.values.contains(secondInstance))
    }

    func test_observation_closure() {
        let first = TestType(name: "Aidar", age: 24)
        let second = TestType(name: "Joe", age: 55)
        let updatedSecond = TestType(name: "Joe", age: 101)

        var actualChanges: [YMapChange<TestType>] = []

        let subscriptionId = map.observe { changes in
            changes.forEach { change in
                actualChanges.append(change)
            }
        }

        map[first.name] = first
        map[second.name] = second

        map[first.name] = nil
        map[second.name] = updatedSecond

        map.unobserve(subscriptionId)

        // Use set here, to compare two arrays by the composition not by order
        XCTAssertEqual(
            Set(actualChanges),
            Set([
                .inserted(key: first.name, value: first),
                .inserted(key: second.name, value: second),
                .removed(key: first.name, value: first),
                .updated(key: second.name, oldValue: second, newValue: updatedSecond)
            ])
        )
    }
    
    /*
     https://www.swiftbysundell.com/articles/using-unit-tests-to-identify-avoid-memory-leaks-in-swift/
     https://alisoftware.github.io/swift/closures/2016/07/25/closure-capture-1/
     */

    func test_observation_closure_IsLeakingWithoutUnobserving() {
        // Create an object (it can be of any type), and hold both
        // a strong and a weak reference to it
        var object = NSObject()
        weak var weakObject = object

        let _ = map.observe { [object] changes in
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

    func test_observation_closure_IsNotLeakingAfterUnobserving() {
        // Create an object (it can be of any type), and hold both
        // a strong and a weak reference to it
        var object = NSObject()
        weak var weakObject = object

        let subscriptionId = map.observe { [object] changes in
            // Capture the object in the closure (note that we need to use
            // a capture list like [object] above in order for the object
            // to be captured by reference instead of by pointer value)
            _ = object
            changes.forEach { _ in }
        }

        // Explicit unobserving, to prevent leaking
        map.unobserve(subscriptionId)

        // When we re-assign our local strong reference to a new object the
        // weak reference should become nil, since the closure should
        // have been run and removed at this point
        // Because we did explicitly unobserve/unsubscribe at this point.
        object = NSObject()
        XCTAssertNil(weakObject)
    }
    
    func test_observation_publisher() {
        let first = TestType(name: "Aidar", age: 24)
        let second = TestType(name: "Joe", age: 55)
        let updatedSecond = TestType(name: "Joe", age: 101)

        var actualChanges: [YMapChange<TestType>] = []

        let cancellable = map.observe().sink { changes in
            changes.forEach { change in
                actualChanges.append(change)
            }
        }
        
        map[first.name] = first
        map[second.name] = second

        map[first.name] = nil
        map[second.name] = updatedSecond
        
        cancellable.cancel()
        
        // Use set here, to compare two arrays by the composition not by order
        XCTAssertEqual(
            Set(actualChanges),
            Set([
                .inserted(key: first.name, value: first),
                .inserted(key: second.name, value: second),
                .removed(key: first.name, value: first),
                .updated(key: second.name, oldValue: second, newValue: updatedSecond)
            ])
        )
    }
    
    func test_observation_publisher_IsLeakingWithoutCancelling() {
        // Create an object (it can be of any type), and hold both
        // a strong and a weak reference to it
        var object = NSObject()
        weak var weakObject = object
        
        let cancellable = map.observe().sink { [object] changes in
            // Capture the object in the closure (note that we need to use
            // a capture list like [object] above in order for the object
            // to be captured by reference instead of by pointer value)
            _ = object
            changes.forEach { _ in }
        }

        // this is to just silence the "unused variable" warning regading `cancellable` variable above
        // remove below two lines to see the warning; it cannot be replace with `_`, because Combine
        // automatically cancells the subscription in that case
        var bag = Set<AnyCancellable>()
        cancellable.store(in: &bag)
        
        // When we re-assign our local strong reference to a new object the
        // weak reference should still persist.
        // Because we didn't explicitly unobserved/unsubscribed.
        object = NSObject()
        XCTAssertNotNil(weakObject)
    }
    
    func test_observation_publisher_IsNotLeakingAfterCancelling() {
        // Create an object (it can be of any type), and hold both
        // a strong and a weak reference to it
        var object = NSObject()
        weak var weakObject = object

        let cancellable = map.observe().sink { [object] changes in
            // Capture the object in the closure (note that we need to use
            // a capture list like [object] above in order for the object
            // to be captured by reference instead of by pointer value)
            _ = object
            changes.forEach { _ in }
        }

        // Explicit cancelling, to prevent leaking
        cancellable.cancel()

        // When we re-assign our local strong reference to a new object the
        // weak reference should become nil, since the closure should
        // have been run and removed at this point
        // Because we did explicitly unobserve/unsubscribe at this point.
        object = NSObject()
        XCTAssertNil(weakObject)
    }
}
