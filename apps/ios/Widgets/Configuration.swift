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
    static var description = IntentDescription("삶의 유한함을 기억하는 위젯. 기본으로 앱의 나의 시간을 사용합니다. 다른 시간을 표시하려면 생년월일을 입력하세요.")
    @Parameter(title: "다른 생년월일 (선택, YYYY-MM-DD)", default: "") var birthday: String
    @Parameter(title: "기준 나이", default: 83.7) var years: Double
    @Parameter(title: "표시 방식", default: .timer) var display: ClockDisplay
    @Parameter(title: "배경", default: .dark) var theme: ClockTheme
    @Parameter(title: "기억할 문장", default: "") var message: String
}
