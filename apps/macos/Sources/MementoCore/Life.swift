import Foundation

public struct Profile: Codable, Equatable {
    public var birthday: String
    public var years: Double
    public init(birthday: String, years: Double) { self.birthday = birthday; self.years = years }
    public static let example = Profile(birthday: "1995-01-01", years: 83.7)
}
public struct Intention: Codable, Equatable {
    public var text: String
    public var date: String
    public init(text: String, date: String) { self.text = text; self.date = date }
}
public struct LifeState: Codable {
    public var profile: Profile?
    public var intention: Intention?
    public var mode: String
    public init(profile: Profile? = nil, intention: Intention? = nil, mode: String = "seconds") {
        self.profile = profile; self.intention = intention; self.mode = mode
    }
}
public enum Variant: String, Codable, CaseIterable {
    case wide, square, slim
    public var label: String { switch self { case .wide: return "가로형"; case .square: return "정사각형"; case .slim: return "한 줄형" } }
    public var width: Double { self == .square ? 190 : 360 }
    public var height: Double { self == .slim ? 84 : 190 }
}
public enum Theme: String, Codable, CaseIterable { case dark, light }
public struct WidgetPreferences: Codable {
    public var variant: Variant
    public var theme: Theme
    public init(variant: Variant = .wide, theme: Theme = .dark) { self.variant = variant; self.theme = theme }
}
public struct SettingsFile: Codable {
    public var app = "mementomori"
    public var version = 1
    public var state: LifeState
    public var widget: WidgetPreferences
    public init(state: LifeState = LifeState(), widget: WidgetPreferences = WidgetPreferences()) {
        self.state = state; self.widget = widget
    }
    public func validated(now: Date = Date(), timeZone: TimeZone = .current) throws -> Self {
        guard app == "mementomori", version == 1 else { throw LifeError.invalid("메멘토모리 설정 파일이 아니거나 지원하지 않는 버전입니다.") }
        guard state.mode == "seconds" || state.mode == "days" else { throw LifeError.invalid("표시 단위를 확인해 주세요.") }
        if let profile = state.profile { try Life.validate(profile, now: now, timeZone: timeZone) }
        if let intention = state.intention {
            guard intention.text.utf16.count <= 100, Life.birthday(intention.date, timeZone: timeZone) != nil else {
                throw LifeError.invalid("오늘의 문장 형식이 올바르지 않습니다.")
            }
        }
        return self
    }
    public static func decode(_ data: Data) throws -> Self {
        guard data.count <= 65536 else { throw LifeError.invalid("설정 파일은 64KB 이하여야 합니다.") }
        do { return try JSONDecoder().decode(Self.self, from: data).validated() }
        catch let error as LifeError { throw error }
        catch { throw LifeError.invalid("설정 파일을 읽을 수 없습니다. 메멘토모리에서 내보낸 JSON 파일을 선택해 주세요.") }
    }
}
public enum LifeError: LocalizedError {
    case invalid(String)
    public var errorDescription: String? { switch self { case .invalid(let message): return message } }
}
public struct Snapshot {
    public let seconds: Int64
    public var days: Int64 { seconds / 86400 }
    public let progress: Double
    public let end: Date
    public var passed: Bool { seconds == 0 }
}
public enum Life {
    public static let year: Double = 365.2425 * 86400
    public static func birthday(_ value: String, timeZone: TimeZone = .current) -> Date? {
        guard value.range(of: "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", options: .regularExpression) != nil else { return nil }
        let parts = value.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, parts[0] >= 1900 else { return nil }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = timeZone
        let components = DateComponents(year: parts[0], month: parts[1], day: parts[2])
        guard let date = calendar.date(from: components) else { return nil }
        let result = calendar.dateComponents([.year, .month, .day], from: date)
        guard result.year == parts[0], result.month == parts[1], result.day == parts[2] else { return nil }
        return date
    }
    public static func dayKey(_ date: Date = Date(), timeZone: TimeZone = .current) -> String {
        let format = DateFormatter(); format.locale = Locale(identifier: "en_US_POSIX")
        format.calendar = Calendar(identifier: .gregorian); format.timeZone = timeZone; format.dateFormat = "yyyy-MM-dd"
        return format.string(from: date)
    }
    public static func validate(_ profile: Profile, now: Date = Date(), timeZone: TimeZone = .current) throws {
        guard let birth = birthday(profile.birthday, timeZone: timeZone) else { throw LifeError.invalid("생년월일을 YYYY-MM-DD 형식으로 입력해 주세요.") }
        guard birth <= now else { throw LifeError.invalid("생년월일은 오늘 또는 그 이전이어야 해요.") }
        guard profile.years.isFinite, (1...120).contains(profile.years) else { throw LifeError.invalid("기준 수명은 1세부터 120세 사이로 입력해 주세요.") }
    }
    public static func snapshot(_ profile: Profile, now: Date = Date(), timeZone: TimeZone = .current) throws -> Snapshot {
        try validate(profile, now: now, timeZone: timeZone)
        let birth = birthday(profile.birthday, timeZone: timeZone)!
        let duration = profile.years * year
        let end = birth.addingTimeInterval(duration)
        return Snapshot(seconds: Int64(max(0, ceil(end.timeIntervalSince(now)))), progress: min(1, max(0, now.timeIntervalSince(birth) / duration)), end: end)
    }
}
