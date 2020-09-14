import XCTest
@testable import CoreLocationMiddleware

final class CoreLocationMiddlewareTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(CoreLocationMiddleware().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
