import XCTest
@testable import YSwift

final class YMapTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_insert() {
        let document = YDocument()
        let map: YMap<SomeType> = document.getOrCreateMap(named: "some_map")
        
        let initialInstance = SomeType(name: "Aidar", age: 24)
        let secondInstance = SomeType(name: "Joe", age: 55)
        
        
        document.transact { txn in
            XCTAssertEqual(map.length(tx: txn), 0)
            map.insert(tx: txn, key: initialInstance.name, value: initialInstance)
            map.insert(tx: txn, key: secondInstance.name, value: secondInstance)
            XCTAssertEqual(map.length(tx: txn), 2)
        }
        
        let finalInstance = document.transact { txn in
            map.get(tx: txn, key: initialInstance.name)
        }
        
        XCTAssertEqual(initialInstance, finalInstance)

        let contains = document.transact { txn in
            map.contains_key(tx: txn, key: secondInstance.name)
        }
        XCTAssertTrue(contains)
    }
    
    func test_remove() {
        let document = YDocument()
        let map: YMap<SomeType> = document.getOrCreateMap(named: "some_map")
        
        let initialInstance = SomeType(name: "Aidar", age: 24)
        let secondInstance = SomeType(name: "Joe", age: 55)
        
        document.transact { txn in
            XCTAssertEqual(map.length(tx: txn), 0)
            map.insert(tx: txn, key: initialInstance.name, value: initialInstance)
            map.insert(tx: txn, key: secondInstance.name, value: secondInstance)
            XCTAssertEqual(map.length(tx: txn), 2)
        }

        document.transact { txn in
            XCTAssertEqual(map.length(tx: txn), 2)
            _ = map.remove(tx: txn, key: secondInstance.name)
            XCTAssertEqual(map.length(tx: txn), 1)
        }
    }
    
    func test_clear() {
        let document = YDocument()
        let map: YMap<SomeType> = document.getOrCreateMap(named: "some_map")
        
        let initialInstance = SomeType(name: "Aidar", age: 24)
        let secondInstance = SomeType(name: "Joe", age: 55)
        
        document.transact { txn in
            XCTAssertEqual(map.length(tx: txn), 0)
            map.insert(tx: txn, key: initialInstance.name, value: initialInstance)
            map.insert(tx: txn, key: secondInstance.name, value: secondInstance)
            XCTAssertEqual(map.length(tx: txn), 2)
        }

        document.transact { txn in
            XCTAssertEqual(map.length(tx: txn), 2)
            map.clear(tx: txn)
            XCTAssertEqual(map.length(tx: txn), 0)
        }
    }
}
