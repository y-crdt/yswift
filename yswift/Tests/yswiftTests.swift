import XCTest
import YNativeFinal
@testable import YSwift

class yswiftTests: XCTestCase {
    func test_Append() throws {
        let doc = Doc()
        let text = doc.getText(name: "some_text")
        let txn = doc.transact()
        text.append(tx: txn, text: "hello, world!")
        let resultString = text.getString(tx: txn)
        txn.free()
        XCTAssertEqual(resultString, "hello, world!")
    }
    
    func test_AppendAndInsert() throws {
        let doc = Doc()
        let text = doc.getText(name: "some_text")
        let txn = doc.transact()
        text.append(tx: txn, text: "hello, world!")
        text.insert(tx: txn, index: 0, chunk: "before that: ")
        let resultString = text.getString(tx: txn)
        txn.free()
        XCTAssertEqual(resultString, "before that: hello, world!")
    }
    
    func test_Length() throws {
        let doc = Doc()
        let text = doc.getText(name: "some_text")
        let txn = doc.transact()
        text.append(tx: txn, text: "abcd")
        let length = text.length(tx: txn)
        txn.free()
        XCTAssertEqual(length, 4)
    }
    
    func test_getExistingText_FromWithinTransaction() throws {
        let doc = Doc()
        let _ = doc.getText(name: "some_text")
        let txn = doc.transact()
        let someText = txn.transactionGetText(name: "some_text")
        txn.free()
        XCTAssertNotNil(someText)
    }
    
    func test_getNonExistingText_FromWithinTransaction() throws {
        let doc = Doc()
        let _ = doc.getText(name: "some_text")
        let txn = doc.transact()
        let anotherText = txn.transactionGetText(name: "anotherText")
        txn.free()
        XCTAssertNil(anotherText)
    }
    
    func test_removeRange() throws {
        let doc = Doc()
        let text = doc.getText(name: "some_text")
        let txn = doc.transact()
        text.append(tx: txn, text: "hello, world!")
        text.removeRange(tx: txn, start: 1, length: 5)
        let resultString = text.getString(tx: txn)
        txn.free()
        XCTAssertEqual(resultString, "h world!")
    }
}
