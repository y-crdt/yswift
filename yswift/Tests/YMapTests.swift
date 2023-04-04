import XCTest
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

    func test_observation() {
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
}
