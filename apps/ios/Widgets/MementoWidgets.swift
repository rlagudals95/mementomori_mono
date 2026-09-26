import SwiftUI
import WidgetKit
import MementoCore

struct ClockEntry: TimelineEntry {
    var date: Date
    var timerStart: Date
    var configuration: ClockConfiguration
    var snapshot: Snapshot?
    var invalid = false
    var example = false
}
struct ClockProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ClockEntry { preview() }
    func snapshot(for configuration: ClockConfiguration, in context: Context) async -> ClockEntry {
        context.isPreview ? preview() : entry(configuration, date: Date())
    }
    func timeline(for configuration: ClockConfiguration, in context: Context) async -> Timeline<ClockEntry> {
        let now = Date()
        let profile = Profile(birthday: configuration.birthday.trimmingCharacters(in: .whitespacesAndNewlines), years: configuration.years)
        guard let dates = try? WidgetClock.dates(profile: profile, now: now) else {
            return Timeline(entries: [entry(configuration, date: now)], policy: .never)
        }
        let entries = dates.map { entry(configuration, date: $0, timerStart: now) }
        return Timeline(entries: entries, policy: entries.last?.snapshot?.passed == true ? .never : .atEnd)
    }
    private func entry(_ configuration: ClockConfiguration, date: Date, timerStart: Date? = nil) -> ClockEntry {
        let birthday = configuration.birthday.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = try? Life.snapshot(Profile(birthday: birthday, years: configuration.years), now: date)
        return ClockEntry(date: date, timerStart: timerStart ?? date, configuration: configuration, snapshot: value, invalid: !birthday.isEmpty && value == nil)
    }
    private func preview() -> ClockEntry {
        let configuration = ClockConfiguration(); let date = Date()
        return ClockEntry(date: date, timerStart: date, configuration: configuration, snapshot: try? Life.snapshot(.example, now: date), example: true)
    }
}

struct ClockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ClockEntry
    var body: some View {
        Group {
            if family == .accessoryRectangular || family == .accessoryInline || family == .accessoryCircular {
                accessory
            } else {
                WidgetFace(snapshot: entry.snapshot, date: entry.date, timerStart: entry.timerStart,
                           timer: entry.configuration.display == .timer, dark: entry.configuration.theme == .dark,
                           compact: family == .systemSmall, message: String(entry.configuration.message.prefix(100)), invalid: entry.invalid, example: entry.example)
            }
        }.widgetURL(entry.snapshot == nil ? URL(string: "mementomori://widget-help") : nil)
            .containerBackground(for: .widget) { entry.configuration.theme == .dark ? Design.ink : Design.paper }
    }
    @ViewBuilder private var accessory: some View {
        if family == .accessoryInline {
            if let value = entry.snapshot {
                Text(value.passed ? "오늘도, 당신의 시간입니다." : "유한한 시간 · \(Design.number(value.days))일")
            } else { Text("mementomori. · 시간을 설정하세요") }
        } else if family == .accessoryCircular {
            if let value = entry.snapshot {
                Gauge(value: value.progress) {
                    Image(systemName: "hourglass")
                } currentValueLabel: {
                    Text(value.passed ? "오늘" : "\(Int(value.progress * 100))%").font(Design.font(12, weight: .bold))
                }.gaugeStyle(.accessoryCircular).accessibilityLabel("지나온 삶 \(Int(value.progress * 100))퍼센트")
            } else { Image(systemName: "hourglass").widgetAccentable() }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text("당신의 시간은 유한합니다.").font(Design.font(11)).lineLimit(1).minimumScaleFactor(0.7)
                if let value = entry.snapshot {
                    if value.passed { Text("오늘도 삶은 계속됩니다.").font(Design.font(13, weight: .bold)) }
                    else if entry.configuration.display == .timer {
                        Text(timerInterval: min(entry.timerStart, entry.date)...value.end, countsDown: true, showsHours: true)
                            .font(Design.font(20, weight: .bold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.4)
                    } else {
                        Text("\(Design.number(value.days))일").font(Design.font(24, weight: .bold)).monospacedDigit()
                    }
                } else { Text(entry.invalid ? "생년월일을 확인해 주세요." : "길게 눌러 시간을 설정하세요.").font(Design.font(11)) }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct MementoClockWidget: Widget {
    let kind = "MementoClock"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ClockConfiguration.self, provider: ClockProvider()) { entry in ClockWidgetView(entry: entry) }
            .configurationDisplayName("메멘토모리")
            .description("자주 보는 곳에, 유한한 시간을. 생년월일과 기준 나이를 설정하세요.")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline, .accessoryCircular])
            .contentMarginsDisabled()
    }
}
@main
struct MementoWidgets: WidgetBundle {
    init() { Design.registerFont() }
    var body: some Widget { MementoClockWidget() }
}
