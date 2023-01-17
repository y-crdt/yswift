import XCTest
import YNativeFinal
@testable import YSwift

class yswiftTests: XCTestCase {
    func testAppend() throws {
        let doc = Doc()
        let text = doc.getText(name: "some_text")
        let txn = doc.transact()
        text.append(tx: txn, text: "hello, world!")
        let resultString = text.getString(tx: txn)
        txn.free()
        XCTAssertEqual(resultString, "hello, world!")
    }
    
    func testAppendAndInsert() throws {
        let doc = Doc()
        let text = doc.getText(name: "some_text")
        let txn = doc.transact()
        text.append(tx: txn, text: "hello, world!")
        text.insert(tx: txn, index: 0, chunk: "before that: ")
        let resultString = text.getString(tx: txn)
        txn.free()
        XCTAssertEqual(resultString, "before that: hello, world!")
    }
}
