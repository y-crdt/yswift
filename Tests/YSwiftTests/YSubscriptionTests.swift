import Foundation

import Combine
import XCTest
@testable import YSwift

class YSubscriptionTests: XCTestCase {
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
    
    private func test_cancel(cancel: (inout YSubscription?) -> Void) {
        // Create an object (it can be of any type), and hold both
        // a strong and a weak reference to it
        var object = NSObject()
        weak var weakObject = object

        var subscription: YSubscription? = text.observe { _ in
            // Capture the object in the closure (note that we need to use
            // a capture list like [object] above in order for the object
            // to be captured by reference instead of by pointer value)
            _ = object
        }

        // Explicit unobserving, to prevent leaking
        cancel(&subscription)

        // When we re-assign our local strong reference to a new object the
        // weak reference should become nil, since the closure should
        // have been run and removed at this point
        // Because we did explicitly unobserve/unsubscribe at this point.
        object = NSObject()
        XCTAssertNil(weakObject)
    }
    
    func test_cancel_deinit() {
        test_cancel { subscription in
            subscription = nil
        }
    }
    
    func test_cancel_explicit() {
        test_cancel { subscription in
            subscription?.cancel()
        }
    }

    /// A subscription may be the last thing standing: the document and the
    /// collection it observed can both be released first (a view model's
    /// stored properties go in an order nobody chose). Cancelling it then must
    /// not reach into a freed store — it did once, as a SIGSEGV in
    /// `Branch::unobserve` on every deinit of a consuming app's document wrapper.
    func test_cancelling_after_the_document_is_gone_is_safe() {
        var document: YDocument? = YDocument()
        var text: YText? = document!.getOrCreateText(named: "prompt")
        let subscription = text!.observe { _ in }
        document = nil
        text = nil
        subscription.cancel()
    }
}
