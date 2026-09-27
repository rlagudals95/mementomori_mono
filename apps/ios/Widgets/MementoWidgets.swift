import SwiftUI
import WidgetKit
import MementoCore
import MementoScenes

struct ClockEntry: TimelineEntry {
    var date: Date
    var timerStart: Date
    var configuration: ClockConfiguration
    var snapshot: Snapshot?
    var invalid = false
    var example = false
    var scene: TimeScene = .hourglass
    var years: Double = 83.7
}
struct ClockProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ClockEntry { preview() }
    func snapshot(for configuration: ClockConfiguration, in context: Context) async -> ClockEntry {
        context.isPreview ? preview() : entry(configuration, date: Date())
    }
    func timeline(for configuration: ClockConfiguration, in context: Context) async -> Timeline<ClockEntry> {
        let now = Date()
        guard let profile = profile(configuration) else {
            return Timeline(entries: [entry(configuration, date: now)], policy: .never)
        }
        guard let dates = try? WidgetClock.dates(profile: profile, now: now) else {
            return Timeline(entries: [entry(configuration, date: now)], policy: .never)
        }
        let entries = dates.map { entry(configuration, date: $0, timerStart: now) }
        return Timeline(entries: entries, policy: entries.last?.snapshot?.passed == true ? .never : .atEnd)
    }
    private func profile(_ configuration: ClockConfiguration) -> Profile? {
        let birthday = configuration.birthday.trimmingCharacters(in: .whitespacesAndNewlines)
        return birthday.isEmpty ? SharedSettings.read()?.state.profile : Profile(birthday: birthday, years: configuration.years)
    }
    private func entry(_ configuration: ClockConfiguration, date: Date, timerStart: Date? = nil) -> ClockEntry {
        let birthday = configuration.birthday.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = profile(configuration).flatMap { try? Life.snapshot($0, now: date) }
        let configuration = configuration
        if birthday.isEmpty, let settings = SharedSettings.read() {
            configuration.display = settings.state.mode == "days" ? .days : .timer
            if configuration.message.isEmpty { configuration.message = Design.thought(settings, at: date) }
        }
        return ClockEntry(date: date, timerStart: timerStart ?? date, configuration: configuration, snapshot: value, invalid: !birthday.isEmpty && value == nil, scene: TimeScene(rawValue: SharedSettings.defaults?.string(forKey: "scene.theme") ?? "") ?? .hourglass, years: profile(configuration)?.years ?? 83.7)
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
                if let snapshot = entry.snapshot {
                    SceneWidgetFace(snapshot: snapshot, scene: entry.scene, years: entry.years, timer: entry.configuration.display == .timer, dark: entry.configuration.theme == .dark, compact: family == .systemSmall)
                } else {
                WidgetFace(snapshot: entry.snapshot, date: entry.date, timerStart: entry.timerStart,
                           timer: entry.configuration.display == .timer, dark: entry.configuration.theme == .dark,
                           compact: family == .systemSmall, message: String(entry.configuration.message.prefix(100)), invalid: entry.invalid, example: entry.example)
                }
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
                        SecondsCountdown(end: value.end, fallback: value.seconds)
                            .font(Design.font(20, weight: .bold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.4)
                    } else {
                        Text("\(Design.number(value.days))일").font(Design.font(24, weight: .bold)).monospacedDigit()
                    }
                } else { Text(entry.invalid ? "생년월일을 확인해 주세요." : "앱에서 시간을 설정하세요.").font(Design.font(11)) }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// Widgets render static artwork; WidgetKit's date text owns the live seconds.
struct SceneWidgetFace: View {
    let snapshot: Snapshot
    let scene: TimeScene
    let years: Double
    let timer: Bool
    let dark: Bool
    let compact: Bool
    private var ink: Color { dark ? Design.paper : Design.ink }
    private var background: Color { dark ? Design.ink : Design.paper }
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 5) {
                if compact {
                    ZStack(alignment: .topLeading) {
                        Text("mementomori.").font(Design.font(10, weight: .bold))
                        if scene == .hourglass {
                            art.frame(width: 100, height: 64)
                                .scaleEffect(1.2).offset(x: 18, y: -4)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else {
                            art.frame(width: 72, height: 44).padding(.top, 14)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }.frame(height: max(56, geometry.size.height - 111), alignment: .topLeading)
                    Text("당신의 시간은 유한합니다.").font(Design.font(9)).opacity(0.65).lineLimit(1)
                    counter(width: geometry.size.width - 28)
                } else {
                    Text("mementomori.").font(Design.font(11, weight: .bold))
                    HStack(spacing: 12) {
                        art.frame(width: geometry.size.width * 0.28)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(snapshot.passed ? "오늘도, 당신의 시간입니다." : "당신의 시간은 유한합니다.")
                                .font(Design.font(11)).opacity(0.65).lineLimit(1).minimumScaleFactor(0.7)
                            counter(width: geometry.size.width * 0.6 - 28)
                            Text(scene.message).font(Design.font(10)).opacity(0.65).lineLimit(2)
                        }
                    }.frame(maxHeight: .infinity)
                }
                LifeLine(progress: snapshot.progress, color: ink)
            }.padding(14).foregroundStyle(ink)
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    private var art: some View {
        TimeSceneView(scene: scene, progress: snapshot.progress, years: years, ink: ink, background: background, motionEnabled: false)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
    @ViewBuilder private func counter(width: CGFloat) -> some View {
        if snapshot.passed { Text("오늘").font(Design.font(28, weight: .bold)) }
        else if timer && compact {
            SquareSecondsCountdown(end: snapshot.end, seconds: snapshot.seconds, width: width, size: 22)
        } else if timer {
            SecondsCountdown(end: snapshot.end, fallback: snapshot.seconds)
                .font(Design.font(30, weight: .bold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
        } else {
            Text("\(Design.number(snapshot.days))일").font(Design.font(28, weight: .bold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
        }
    }
}

struct MementoClockWidget: Widget {
    let kind = "MementoClock"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ClockConfiguration.self, provider: ClockProvider()) { entry in ClockWidgetView(entry: entry) }
            .configurationDisplayName("메멘토모리")
            .description("자주 보는 곳에, 유한한 시간을. 앱에서 설정한 나의 시간이 자동으로 표시됩니다.")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline, .accessoryCircular])
            .contentMarginsDisabled()
    }
}
@main
struct MementoWidgets: WidgetBundle {
    init() { Design.registerFont() }
    var body: some Widget { MementoClockWidget() }
}
