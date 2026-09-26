import XCTest
@testable import MementoCore

final class SplitSecondsTests: XCTestCase {
    func testGroupingAndBorrowAcrossMillion() {
        XCTAssertEqual(SplitSeconds.text(1_797_552_425), "1,797,\n552,425초")
        XCTAssertEqual(SplitSeconds.text(1_797_000_000), "1,797,\n000,000초")
        XCTAssertEqual(SplitSeconds.text(1_796_999_999), "1,796,\n999,999초")
        XCTAssertEqual(SplitSeconds.text(1_000_000), "1,\n000,000초")
        XCTAssertEqual(SplitSeconds.text(999_999), "999,999초")
        XCTAssertEqual(SplitSeconds.text(-1), "0초")
    }
}
