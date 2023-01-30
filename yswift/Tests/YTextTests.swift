import XCTest
@testable import YSwift

struct SomeEmbed: Codable, Equatable {
    let title: String
}

class YTextTests: XCTestCase {
    func test_append() {
        let document = YDocument()
        let text = document.getOrCreateText(named: "some_text")
        let resultString: String = document.transact { txn in
            text.append(tx: txn, text: "hello, world!")
            return text.getString(tx: txn)
        }
        XCTAssertEqual(resultString, "hello, world!")
    }
    
    func test_appendAndInsert() throws {
        let document = YDocument()
        let text = document.getOrCreateText(named: "some_text")
        let resultString: String = document.transact { txn in
            text.append(tx: txn, text: "hello, world!")
            text.insert(tx: txn, index: 0, chunk: "before that: ")
            return text.getString(tx: txn)
        }
        XCTAssertEqual(resultString, "before that: hello, world!")
    }
    

    func test_format() {
        let document = YDocument()
        let text = document.getOrCreateText(named: "some_text")
        
        let initialAttrs: [String: String] = ["weight": "bold"]
        var decodedAttrs: [String: String] = [:]
        
        let subscriptionId = text.observe { deltas in
            deltas.forEach {
                switch $0 {
                case let .inserted(_, attrs):
                    let decoded: [(String, String)] = attrs.map {
                        let decoder = JSONDecoder()
                        let decodedValue = try! decoder.decode(String.self, from: $1.data(using: .utf8)!)
                        return ($0, decodedValue)
                    }
                    decodedAttrs = Dictionary(uniqueKeysWithValues: decoded)
                default: break
                }
            }
        }
        
        document.transact { txn in
            text.append(tx: txn, text: "abc")
            text.format(tx: txn, index: 0, length: 3, attrs: initialAttrs)
        }
        
        text.unobserve(subscriptionId)
        
        XCTAssertEqual(initialAttrs, decodedAttrs)
    }
    
    func test_insertEmbed() {
        let document = YDocument()
        let text = document.getOrCreateText(named: "some_text")
        
        let content = SomeEmbed(title: "title_123")
        var insertedContent: SomeEmbed?
        
        let subscriptionId = text.observe { deltas in
            deltas.forEach {
                switch $0 {
                case let .inserted(value, _):
                    let decoder = JSONDecoder()
                    let decodedValue = try! decoder.decode(SomeEmbed.self, from: value.data(using: .utf8)!)
                    insertedContent = decodedValue
                default: break
                }
            }
        }
        
        let length: UInt32 = document.transact { txn in
            text.insertEmbed(tx: txn, index: 0, content: content)
            return text.length(tx: txn)
        }
        
        text.unobserve(subscriptionId)
        
        XCTAssertEqual(length, 1)
        XCTAssertEqual(content, insertedContent)
    }
    
    func test_length() throws {
        let document = YDocument()
        let text = document.getOrCreateText(named: "some_text")
        let length: UInt32 = document.transact { txn in
            text.append(tx: txn, text: "abcd")
            return text.length(tx: txn)
        }
        XCTAssertEqual(length, 4)
    }
    
    func test_getExistingText_FromWithinTransaction() throws {
        let document = YDocument()
        let _ = document.getOrCreateText(named: "some_text")
        let existingText = document.transact { txn in
            txn.transactionGetText(name: "some_text")
        }
        XCTAssertNotNil(existingText)
    }
    
    func test_getNonExistingText_FromWithinTransaction() throws {
        let document = YDocument()
        let _ = document.getOrCreateText(named: "some_text")
        let anotherText = document.transact { txn in
            txn.transactionGetText(name: "another_text")
        }
        XCTAssertNil(anotherText)
    }
    
    func test_removeRange() throws {
        let document = YDocument()
        let text = document.getOrCreateText(named: "some_text")
        let resultString: String = document.transact { txn in
            text.append(tx: txn, text: "hello, world!")
            text.removeRange(tx: txn, start: 1, length: 5)
            return text.getString(tx: txn)
        }
        XCTAssertEqual(resultString, "h world!")
    }
    
    func test_observation() {
        let document = YDocument()
        let text = document.getOrCreateText(named: "some_text")
        
        var insertedValue = String()
        
        let subscriptionId = text.observe { deltas in
            deltas.forEach {
                switch $0 {
                case let .inserted(value, _):
                    let decoder = JSONDecoder()
                    let decodedValue = try! decoder.decode(String.self, from: value.data(using: .utf8)!)
                    insertedValue = decodedValue
                default: break
                }
            }
        }
        
        document.transact { txn in
            text.append(tx: txn, text: "asd")
        }
        
        text.unobserve(subscriptionId)
        
        XCTAssertEqual(insertedValue, "asd")
    }
    
    /*
     https://www.swiftbysundell.com/articles/using-unit-tests-to-identify-avoid-memory-leaks-in-swift/
     https://alisoftware.github.io/swift/closures/2016/07/25/closure-capture-1/
     */
    
    func test_observationIsLeaking() {
        let document = YDocument()
        let text = document.getOrCreateText(named: "some_text")
        
        // Create an object (it can be of any type), and hold both
        // a strong and a weak reference to it
        var object = NSObject()
        weak var weakObject = object
        
        let _ = text.observe { [object] deltas in
            // Capture the object in the closure (note that we need to use
            // a capture list like [object] above in order for the object
            // to be captured by reference instead of by pointer value)
            _ = object
            deltas.forEach { _ in }
        }
        
        // When we re-assign our local strong reference to a new object the
        // weak reference should still persist.
        // Because we didn't explicitly unobserved/unsubscribed.
        object = NSObject()
        XCTAssertNotNil(weakObject)
    }
    
    func test_observation_IsNotLeaking_afterUnobserving() {
        let document = YDocument()
        let text = document.getOrCreateText(named: "some_text")
        
        // Create an object (it can be of any type), and hold both
        // a strong and a weak reference to it
        var object = NSObject()
        weak var weakObject = object
        
        let subscriptionId = text.observe { [object] deltas in
            // Capture the object in the closure (note that we need to use
            // a capture list like [object] above in order for the object
            // to be captured by reference instead of by pointer value)
            _ = object
            deltas.forEach { _ in }
        }
        
        // Explicit unobserving, to prevent leaking
        text.unobserve(subscriptionId)
        
        // When we re-assign our local strong reference to a new object the
        // weak reference should become nil, since the closure should
        // have been run and removed at this point
        // Because we did explicitly unobserve/unsubscribe at this point.
        object = NSObject()
        XCTAssertNil(weakObject)
    }
}
