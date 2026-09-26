import AppIntents

enum ClockDisplay: String, AppEnum {
    case days, timer
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "표시 방식")
    static var caseDisplayRepresentations: [ClockDisplay: DisplayRepresentation] = [.days: "남은 날", .timer: "흐르는 시간"]
}
enum ClockTheme: String, AppEnum {
    case dark, light
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "배경")
    static var caseDisplayRepresentations: [ClockTheme: DisplayRepresentation] = [.dark: "다크", .light: "라이트"]
}
struct ClockConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "나의 시간"
    static var description = IntentDescription("삶의 유한함을 기억하는 위젯. 생년월일은 YYYY-MM-DD 형식으로 입력하세요.")
    @Parameter(title: "생년월일 (YYYY-MM-DD)", default: "") var birthday: String
    @Parameter(title: "기준 나이", default: 83.7) var years: Double
    @Parameter(title: "표시 방식", default: .days) var display: ClockDisplay
    @Parameter(title: "배경", default: .dark) var theme: ClockTheme
    @Parameter(title: "기억할 문장", default: "") var message: String
}
