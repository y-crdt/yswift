import XCTest

struct TestType: Codable, Equatable, Hashable {
    let name: String
    let age: Int
}

extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak!", file: file, line: line)
        }
    }
}
