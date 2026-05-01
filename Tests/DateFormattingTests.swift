import XCTest
@testable import VibeHelper

@MainActor
final class DateFormattingTests: XCTestCase {

    func testTokenCountFormatting() {
        XCTAssertEqual(0.formattedTokenCount, "0")
        XCTAssertEqual(500.formattedTokenCount, "500")
        XCTAssertEqual(999.formattedTokenCount, "999")
        XCTAssertEqual(1000.formattedTokenCount, "1.0K")
        XCTAssertEqual(1500.formattedTokenCount, "1.5K")
        XCTAssertEqual(9999.formattedTokenCount, "10.0K")
        XCTAssertEqual(10000.formattedTokenCount, "10.0K")
        XCTAssertEqual(100000.formattedTokenCount, "100.0K")
        XCTAssertEqual(1000000.formattedTokenCount, "1.0M")
        XCTAssertEqual(1500000.formattedTokenCount, "1.5M")
        XCTAssertEqual(10000000.formattedTokenCount, "10.0M")
    }

    func testDurationFormatting() {
        // Seconds only
        XCTAssertEqual(TimeInterval(0).formattedDuration(), "0s")
        XCTAssertEqual(TimeInterval(1).formattedDuration(), "1s")
        XCTAssertEqual(TimeInterval(30).formattedDuration(), "30s")
        XCTAssertEqual(TimeInterval(59).formattedDuration(), "59s")

        // Minutes and seconds
        XCTAssertEqual(TimeInterval(60).formattedDuration(), "1m 0s")
        XCTAssertEqual(TimeInterval(61).formattedDuration(), "1m 1s")
        XCTAssertEqual(TimeInterval(90).formattedDuration(), "1m 30s")
        XCTAssertEqual(TimeInterval(120).formattedDuration(), "2m 0s")
        XCTAssertEqual(TimeInterval(150).formattedDuration(), "2m 30s")

        // Hours and minutes
        XCTAssertEqual(TimeInterval(3600).formattedDuration(), "1h 0m")
        XCTAssertEqual(TimeInterval(3601).formattedDuration(), "1h 0m")
        XCTAssertEqual(TimeInterval(3660).formattedDuration(), "1h 1m")
        XCTAssertEqual(TimeInterval(3661).formattedDuration(), "1h 1m")
        XCTAssertEqual(TimeInterval(7322).formattedDuration(), "2h 2m")
    }

    func testDateFormatting() {
        let calendar = Calendar.current

        // Test that formatters are cached (static)
        let date1 = Date()
        let short1 = date1.shortFormatted
        let short2 = date1.shortFormatted
        XCTAssertEqual(short1, short2)

        let date2 = calendar.date(byAdding: .day, value: 1, to: date1) ?? date1
        let day1 = date2.dayFormatted
        XCTAssertNotEqual(short1, day1)
    }
}
