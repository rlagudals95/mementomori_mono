import XCTest
@testable import MementoCore

final class LifeTests: XCTestCase {
    let zone = TimeZone(secondsFromGMT: 9 * 3600)!
    func testCalendarValidation() {
        XCTAssertNil(Life.birthday("2001-02-29", timeZone: zone))
        XCTAssertNil(Life.birthday("2000-04-31", timeZone: zone))
        XCTAssertNil(Life.birthday("2000-13-01", timeZone: zone))
        XCTAssertNil(Life.birthday("1800-01-01", timeZone: zone))
        XCTAssertNotNil(Life.birthday("2000-02-29", timeZone: zone))
    }
    func testClockCatchupAndClamping() throws {
        let profile = Profile(birthday: "2000-01-01", years: 83.7)
        let birth = Life.birthday(profile.birthday, timeZone: zone)!
        let now = birth.addingTimeInterval(30 * Life.year)
        let first = try Life.snapshot(profile, now: now, timeZone: zone)
        let later = try Life.snapshot(profile, now: now.addingTimeInterval(259201), timeZone: zone)
        XCTAssertEqual(first.seconds - later.seconds, 259201)
        XCTAssertEqual(first.progress, 30 / 83.7, accuracy: 1e-10)
        let passed = try Life.snapshot(profile, now: birth.addingTimeInterval(100 * Life.year), timeZone: zone)
        XCTAssertEqual(passed.seconds, 0); XCTAssertEqual(passed.progress, 1); XCTAssertTrue(passed.passed)
    }
    func testInvalidInputs() {
        XCTAssertThrowsError(try Life.snapshot(Profile(birthday: "2099-01-01", years: 83.7)))
        for years in [0.0, 121, Double.nan, Double.infinity] {
            XCTAssertThrowsError(try Life.snapshot(Profile(birthday: "2000-01-01", years: years)))
        }
    }
    func testSharedWebSettings() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("shared/contracts/settings-example.json"))
        let settings = try SettingsFile.decode(data)
        XCTAssertEqual(settings.state.profile?.birthday, "1995-01-01")
        XCTAssertEqual(settings.widget.variant, .wide)
        let encoded = try JSONEncoder().encode(settings)
        let decoded = try SettingsFile.decode(encoded)
        XCTAssertEqual(decoded.state.intention, settings.state.intention)
        XCTAssertThrowsError(try SettingsFile.decode(Data("{}".utf8)))
        XCTAssertThrowsError(try SettingsFile.decode(Data(repeating: 32, count: 65537)))
        var invalid = settings; invalid.version = 2
        XCTAssertThrowsError(try invalid.validated())
    }
    func testSharedWebCountdownFixtures() throws {
        struct Fixture: Decodable { var timezone: String; var profile: Profile; var now: String; var seconds: Int64; var days: Int64; var progress: Double }
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("shared/fixtures/life-cases.json"))
        let fixtures = try JSONDecoder().decode([Fixture].self, from: data)
        let format = ISO8601DateFormatter(); format.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        for fixture in fixtures {
            let value = try Life.snapshot(fixture.profile, now: format.date(from: fixture.now)!, timeZone: TimeZone(identifier: fixture.timezone)!)
            XCTAssertEqual(value.seconds, fixture.seconds)
            XCTAssertEqual(value.days, fixture.days)
            XCTAssertEqual(value.progress, fixture.progress, accuracy: 1e-10)
        }
    }

}
