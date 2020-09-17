import XCTest
@testable import SwiftRex
@testable import CoreLocationMiddleware

final class CoreLocationMiddlewareTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        let store = TestStore()
        
        let sut = CoreLocationMiddleware()
        sut.receiveContext(getState: store.getState, output: store.actionHandler)
        
        var after1 = AfterReducer.do {
            print("Test")
        }
        sut.handle(action: .stopMonitoring, from: .here(), afterReducer: &after1)
        after1.reducerIsDone()

        XCTAssertEqual(store.actionsReceived, [.stopMonitoring])
        
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
