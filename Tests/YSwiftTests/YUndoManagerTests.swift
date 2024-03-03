import Combine
import XCTest
@testable import YSwift

class TestMetadata {
    public let value: String
    init(_ value: String) {
        self.value = value
    }
}

class YUndoManagerTests: XCTestCase {
    var document: YDocument!
    var text: YText!
    var manager: YUndoManager<TestMetadata>!
    
    override func setUp() {
        document = YDocument()
        text = document.getOrCreateText(named: "test")
        manager = document.undoManager(trackedRefs: [text])
    }
    
    override func tearDown() {
        document = nil
        text = nil
        manager = nil
    }
    
    
    func test_undoTextBasic() throws {
        text.insert("1221", at: 0)
        manager.wrap()
        text.insert("3", at: 2)
        manager.wrap()
        text.insert("3", at: 3)
        manager.wrap()
        
        XCTAssertEqual(text.getString(), "123321")
        
        XCTAssert (try manager.undo())
        XCTAssertEqual(text.getString(), "12321")
        
        XCTAssert (try manager.undo())
        XCTAssertEqual(text.getString(), "1221")
        
        text.insert("3", at: 2)
        XCTAssertEqual(text.getString(), "12321")
    }
    
    func test_undoEvents() throws {
        var received = TestMetadata("")
        let on_added = manager.observeAdded({ (e, metadata) -> TestMetadata? in
            let m = metadata ?? TestMetadata("")
            return TestMetadata(m.value + "A")
        })
        let on_popped = manager.observePopped({ (e, metadata) -> TestMetadata? in
            received = metadata!
            return metadata
        })
        
        text.insert("abc", at: 0)
        
        XCTAssert (try manager.undo())
        XCTAssertEqual(received.value, "A")
        
        XCTAssert (try manager.redo())
        XCTAssertEqual(received.value, "A")
    }
}
