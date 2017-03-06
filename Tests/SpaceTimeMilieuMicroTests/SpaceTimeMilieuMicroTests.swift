import XCTest
@testable import SpaceTimeMilieuMicro

class SpaceTimeMilieuMicroTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(SpaceTimeMilieuMicro().text, "Hello, World!")
    }


    static var allTests : [(String, (SpaceTimeMilieuMicroTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
