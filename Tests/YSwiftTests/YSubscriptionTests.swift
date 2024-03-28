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
    
    // This causes memory to keep growing and I am not sure why
    // I checked that UniFFI YSubscription struct is being dropped accordingly
    // I also verified that the memory increase also happened when we used subscriptionIds and unobserve
    func disabled_test_allocateTooMany() {
        for i in 1...1000000000 {
            _ = text.observe { _ in }
            
            if i % 1000000 == 0 {
                print("\(Date()) Iterations: \(i) Resident Size: \(residentSize() ?? 0)")
            }
        }
        
        print("Done!")
    }
    
    private func residentSize() -> UInt64? {
        var info = mach_task_basic_info()
        let MACH_TASK_BASIC_INFO_COUNT = MemoryLayout<mach_task_basic_info>.stride/MemoryLayout<natural_t>.stride
        var count = mach_msg_type_number_t(MACH_TASK_BASIC_INFO_COUNT)

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: MACH_TASK_BASIC_INFO_COUNT) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }

        guard kerr == KERN_SUCCESS else {
            return nil
        }
        
        return info.resident_size
    }
}
