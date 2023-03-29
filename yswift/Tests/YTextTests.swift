import XCTest
@testable import YSwift

class YTextTests: XCTestCase {
    var document: YDocument!
    var text: YText!
    
    override func setUp() {
        document = YDocument()
        text = document.getOrCreateText(named: "test")
    }
    
    override func tearDown() {
        document = nil
        text = nil
    }
    
    func test_append() {
        text.append(text: "hello, world!")
        
        XCTAssertEqual(text.getString(), "hello, world!")
    }
    
    func test_appendAndInsert() throws {
        text.append(text: "trailing text")
        text.insert(at: 0, text: "leading text, ")
        
        XCTAssertEqual(text.getString(), "leading text, trailing text")
    }

    func test_format() {
        let expectedAttributes = ["weight": "bold"]
        var actualAttributes: [String: String] = [:]

        let subscriptionId = text.observe { deltas in
            deltas.forEach {
                switch $0 {
                case let .retained(_, attrs):
                    let decoded: [(String, String)] = attrs.map {
                        let decoder = JSONDecoder()
                        let decodedValue = try! decoder.decode(String.self, from: $1.data(using: .utf8)!)
                        return ($0, decodedValue)
                    }
                    actualAttributes = Dictionary(uniqueKeysWithValues: decoded)
                default: break
                }
            }
        }
        
        text.append(text: "abc")
        text.format(at: 0, length: 3, attributes: expectedAttributes)

        text.unobserve(subscriptionId)

        XCTAssertEqual(expectedAttributes, actualAttributes)
    }

    func test_insertWithAttributes() {
        let expectedAttributes = ["weight": "bold"]
        var actualAttributes: [String: String] = [:]

        let subscriptionId = text.observe { deltas in
            deltas.forEach {
                switch $0 {
                case let .inserted(_, attrs):
                    let decoded: [(String, String)] = attrs.map {
                        let decoder = JSONDecoder()
                        let decodedValue = try! decoder.decode(String.self, from: $1.data(using: .utf8)!)
                        return ($0, decodedValue)
                    }
                    actualAttributes = Dictionary(uniqueKeysWithValues: decoded)
                default: break
                }
            }
        }
        
        text.insertWithAttributes(at: 0, text: "abc", attributes: expectedAttributes)
        
        text.unobserve(subscriptionId)

        XCTAssertEqual(text.getString(), "abc")
        XCTAssertEqual(expectedAttributes, actualAttributes)
    }
    
    func test_insertEmbed() {
        let embed = SomeType(name: "Aidar", age: 24)
        var insertedEmbed: SomeType?

        let subscriptionId = text.observe { deltas in
            deltas.forEach {
                switch $0 {
                case let .inserted(value, _):
                    let decoder = JSONDecoder()
                    let decodedValue = try! decoder.decode(SomeType.self, from: value.data(using: .utf8)!)
                    insertedEmbed = decodedValue
                default: break
                }
            }
        }
        
        text.insertEmbed(at: 0, embed: embed)

        text.unobserve(subscriptionId)

        XCTAssertEqual(embed, insertedEmbed)
        XCTAssertEqual(text.length(), 1)
    }

    func test_insertEmbedWithAttributes() {
        let embed = SomeType(name: "Aidar", age: 24)
        var insertedEmbed: SomeType?

        let expectedAttributes = ["weight": "bold"]
        var actualAttributes: [String: String] = [:]

        let subscriptionId = text.observe { deltas in
            deltas.forEach {
                switch $0 {
                case let .inserted(value, attrs):
                    let decoder = JSONDecoder()
                    let decodedValue = try! decoder.decode(SomeType.self, from: value.data(using: .utf8)!)
                    let decodedAttributes: [(String, String)] = attrs.map {
                        let decoder = JSONDecoder()
                        let decodedValue = try! decoder.decode(String.self, from: $1.data(using: .utf8)!)
                        return ($0, decodedValue)
                    }
                    insertedEmbed = decodedValue
                    actualAttributes = Dictionary(uniqueKeysWithValues: decodedAttributes)
                default: break
                }
            }
        }

        text.insertEmbedWithAttributes(at: 0, embed: embed, attributes: expectedAttributes)

        text.unobserve(subscriptionId)

        XCTAssertEqual(embed, insertedEmbed)
        XCTAssertEqual(expectedAttributes, actualAttributes)
    }
    
    func test_length() throws {
        text.append(text: "abcd")
        XCTAssertEqual(text.length(), 4)
    }

    func test_removeRange() throws {
        text.append(text: "few apples")
        text.removeRange(start: 0, length: 4)
        
        XCTAssertEqual(text.getString(), "apples")
    }

    func test_observation() {
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

        text.append(text: "test")

        text.unobserve(subscriptionId)

        XCTAssertEqual(insertedValue, "test")
    }

    /*
     https://www.swiftbysundell.com/articles/using-unit-tests-to-identify-avoid-memory-leaks-in-swift/
     https://alisoftware.github.io/swift/closures/2016/07/25/closure-capture-1/
     */

    func test_observationIsLeaking_withoutUnobserving() {
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
