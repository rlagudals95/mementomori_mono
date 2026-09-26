import XCTest
@testable import MementoCore

final class WidgetClockTests: XCTestCase {
    let zone = TimeZone(secondsFromGMT: 0)!
    func testDayEntriesFollowCountdownBoundaryRatherThanMidnight() throws {
        let profile = Profile(birthday: "2000-01-01", years: 83.7)
        let end = try Life.snapshot(profile, now: Life.birthday(profile.birthday, timeZone: zone)!, timeZone: zone).end
        let now = end.addingTimeInterval(-10 * 86400 - 100)
        let dates = try WidgetClock.dates(profile: profile, now: now, timeZone: zone)
        XCTAssertEqual(dates.count, 8)
        XCTAssertEqual(dates[0], now)
        XCTAssertEqual(dates[1].timeIntervalSince(now), 101, accuracy: 0.01)
        XCTAssertEqual(try Life.snapshot(profile, now: dates[0], timeZone: zone).days, 10)
        XCTAssertEqual(try Life.snapshot(profile, now: dates[1], timeZone: zone).days, 9)
        XCTAssertEqual(try Life.snapshot(profile, now: dates[7], timeZone: zone).days, 3)
    }
    func testTimerStopsAtReferenceAndNeverCountsBackUp() throws {
        let profile = Profile(birthday: "2000-01-01", years: 1)
        let end = try Life.snapshot(profile, now: Life.birthday(profile.birthday, timeZone: zone)!, timeZone: zone).end
        let now = end.addingTimeInterval(-20)
        let dates = try WidgetClock.dates(profile: profile, now: now, timeZone: zone)
        XCTAssertEqual(dates, [now, end])
        XCTAssertTrue(try Life.snapshot(profile, now: dates.last!, timeZone: zone).passed)
        XCTAssertEqual(try WidgetClock.dates(profile: profile, now: end.addingTimeInterval(100), timeZone: zone), [end.addingTimeInterval(100)])
    }
    func testInvalidWidgetProfileDoesNotGetExampleCountdown() {
        XCTAssertThrowsError(try WidgetClock.dates(profile: Profile(birthday: "", years: 83.7)))
        XCTAssertThrowsError(try WidgetClock.dates(profile: Profile(birthday: "2099-01-01", years: 83.7)))
        XCTAssertThrowsError(try WidgetClock.dates(profile: Profile(birthday: "2000-01-01", years: 0)))
    }
}
