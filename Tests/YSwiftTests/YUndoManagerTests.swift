import Combine
import XCTest
@testable import YSwift

class YUndoManagerTests: XCTestCase {
    var document: YDocument!
    var text: YText!
    var manager: YUndoManager<AnyObject>!
    
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
        text.insert("3", at: 2)
        text.insert("3", at: 3)
        
        XCTAssertEqual(text.getString(), "123321")
        
        XCTAssert (try manager.undo())
        XCTAssertEqual(text.getString(), "12321")
        
        XCTAssert (try manager.undo())
        XCTAssertEqual(text.getString(), "1221")
        
        text.insert("3", at: 2)
        XCTAssertEqual(text.getString(), "12321")
    }
    
    func test_undoEvents() throws {
        var received = -1
        let on_added = manager.observeAdded({ (e, metadata) -> AnyObject? in
            if let metadata {
                var counter = metadata as! Int
                counter += 1
                return counter as AnyObject
            } else {
                return 0 as AnyObject
            }
        })
        let on_popped = manager.observePopped({ (e, metadata) -> AnyObject? in
            received = metadata as! Int
            return metadata
        })
        
        text.insert("abc", at: 0)
        
        XCTAssert (try manager.undo())
        XCTAssertEqual(received, 0)
        
        XCTAssert (try manager.redo())
        XCTAssertEqual(received, 1)
    }
}
