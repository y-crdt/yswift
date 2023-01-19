import XCTest
import YNativeFinal
@testable import YSwift

class YTextTests: XCTestCase {
    func test_Append() {
        let document = YDocument()
        let text = document.getOrCreateText(named: "some_text")
        let resultString: String = document.transact { txn in
            text.append(tx: txn, text: "hello, world!")
            return text.getString(tx: txn)
        }
        XCTAssertEqual(resultString, "hello, world!")
    }
    
    func test_AppendAndInsert() throws {
        let document = YDocument()
        let text = document.getOrCreateText(named: "some_text")
        let resultString: String = document.transact { txn in
            text.append(tx: txn, text: "hello, world!")
            text.insert(tx: txn, index: 0, chunk: "before that: ")
            return text.getString(tx: txn)
        }
        XCTAssertEqual(resultString, "before that: hello, world!")
    }
    
    func test_Length() throws {
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
}
