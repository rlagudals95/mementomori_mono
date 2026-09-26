import SwiftUI
import CoreText
import UIKit
import MementoCore

enum SharedSettings {
    static let group = "group.com.rlagudals95.mementomori"
    static let key = "settings.v1"
    static var defaults: UserDefaults? { UserDefaults(suiteName: group) }
    static func read() -> SettingsFile? {
        defaults?.data(forKey: key).flatMap { try? SettingsFile.decode($0) }
    }
    static func write(_ settings: SettingsFile) {
        if let data = try? JSONEncoder().encode(settings) { defaults?.set(data, forKey: key) }
    }
}

enum Design {
    static let ink = Color(red: 0.09, green: 0.09, blue: 0.09)
    static let paper = Color(red: 0.98, green: 0.98, blue: 0.98)
    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let face = weight == .bold ? "Bold" : (weight == .semibold ? "SemiBold" : (weight == .medium ? "Medium" : "Regular"))
        return .custom("PretendardVariable-\(face)", size: size)
    }
    static func registerFont() {
        guard let url = Bundle.main.url(forResource: "PretendardVariable", withExtension: "ttf") else { return }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
    static func number(_ value: Int64) -> String { value.formatted(.number.locale(Locale(identifier: "en_US"))) }
    static func thought(_ settings: SettingsFile, at date: Date) -> String {
        if let intention = settings.state.intention, intention.date == Life.dayKey(date), !intention.text.isEmpty { return intention.text }
        return settings.state.mode == "days" ? "오늘은 다시 오지 않습니다." : "이 1초는 돌아오지 않습니다."
    }
}

struct LifeLine: View {
    var progress: Double
    var color: Color = .primary
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().fill(color.opacity(0.2)).frame(height: 1)
                Rectangle().fill(color).frame(width: geometry.size.width * progress, height: 1)
                Circle().fill(color).frame(width: 5, height: 5).offset(x: max(0, (geometry.size.width - 5) * progress))
            }.frame(maxHeight: .infinity)
        }.frame(height: 6).accessibilityHidden(true)
    }
}

struct SecondsCountdown: View {
    let end: Date
    let fallback: Int64
    var body: some View {
        if #available(iOS 18.0, *) {
            Text(.currentDate, format: .offset(to: end, allowedFields: [.second], maxFieldCount: 1, sign: .never)
                .locale(Locale(identifier: "ko_KR")))
        } else {
            Text("\(Design.number(fallback))초")
        }
    }
}

struct SquareSecondsCountdown: View {
    let end: Date
    let seconds: Int64
    let width: CGFloat
    let size: CGFloat
    var body: some View {
        if #available(iOS 18.0, *), seconds >= 1_000_000 {
            // Measure with the same SwiftUI font as the live text, so commas
            // land on the exact split boundary without leaking onto either row.
            VStack(alignment: .trailing, spacing: 0) {
                probe("4,000,").hidden()
                    .overlay(alignment: .leading) { fullCounter }
                    .clipped().accessibilityHidden(true)
                probe("000,000초").hidden()
                    .overlay(alignment: .trailing) { fullCounter }
                    .clipped()
            }.frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityElement(children: .contain).accessibilityIdentifier("square-counter")
        } else {
            if #available(iOS 18.0, *) { live.frame(maxWidth: .infinity, alignment: .trailing) }
            else { Text(SplitSeconds.text(seconds)).multilineTextAlignment(.trailing) }
        }
    }
    private func probe(_ value: String) -> some View {
        Text(value).font(Design.font(size, weight: .bold)).monospacedDigit()
            .lineLimit(1).fixedSize()
    }
    private var fullCounter: some View {
        probe("4,000,000,000초").hidden().overlay(alignment: .trailing) { live }
    }
    private var live: some View {
        SecondsCountdown(end: end, fallback: seconds)
            .font(Design.font(size, weight: .bold)).monospacedDigit()
            .multilineTextAlignment(.trailing).lineLimit(1)
    }
}

struct WidgetFace: View {
    var snapshot: Snapshot?
    var date: Date
    var timerStart: Date
    var timer = false
    var dark = true
    var compact = false
    var message = ""
    var invalid = false
    var example = false
    var setupMessage = "앱에서 나의 시간을 설정하세요."
    private var ink: Color { dark ? Design.paper : Design.ink }

    var body: some View {
        GeometryReader { geometry in
            let numberSize: CGFloat = compact ? min(30, max(22, (geometry.size.width - 32) / 5.2)) : min(44, max(30, (geometry.size.height - 111) / 1.2))
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("mementomori.").font(Design.font(12, weight: .bold))
                    Spacer(minLength: 0)
                    Text("M / M").font(Design.font(10)).opacity(0.55)
                }
                Spacer(minLength: 6)
                if let snapshot {
                    VStack(alignment: .leading, spacing: 4) {
                        Text((example ? "예시 · " : "") + (snapshot.passed ? "오늘도, 당신의 시간입니다." : "당신의 시간은 유한합니다."))
                            .font(Design.font(compact ? 11 : 13)).opacity(0.65).lineLimit(1).minimumScaleFactor(0.8)
                        Group {
                            if snapshot.passed { Text("오늘") }
                            else if timer && compact {
                                SquareSecondsCountdown(end: snapshot.end, seconds: snapshot.seconds,
                                                       width: geometry.size.width - 32, size: numberSize)
                            }
                            else if timer { SecondsCountdown(end: snapshot.end, fallback: snapshot.seconds) }
                            else { Text("\(Design.number(snapshot.days))일") }
                        }.font(Design.font(numberSize, weight: .bold)).monospacedDigit()
                            .lineLimit(compact && timer ? 2 : 1).multilineTextAlignment(compact && timer ? .trailing : .leading)
                            .minimumScaleFactor(0.75).frame(maxWidth: .infinity, alignment: compact && timer ? .trailing : .leading)
                    }
                    Spacer(minLength: 6)
                    LifeLine(progress: snapshot.progress, color: ink)
                    if !compact {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(snapshot.passed ? "오늘도 삶은 계속됩니다." : (message.isEmpty ? "이 1초는 돌아오지 않습니다." : message))
                                .font(Design.font(12)).lineLimit(1).minimumScaleFactor(0.8)
                            Spacer(minLength: 0)
                            Text("\(Int(snapshot.progress * 100))%")
                                .font(Design.font(11)).opacity(0.5)
                                .accessibilityLabel("지나온 \(Int(snapshot.progress * 100))퍼센트")
                        }.padding(.top, 8)
                    }
                } else {
                    Text(invalid ? "설정을 확인해 주세요." : "당신의 시간은\n유한합니다.")
                        .font(Design.font(compact ? 22 : 26, weight: .bold)).lineLimit(2)
                        .minimumScaleFactor(0.7).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 6)
                    Text(invalid ? "생년월일과 기준 나이를 확인해 주세요." : setupMessage)
                        .font(Design.font(12)).opacity(0.65).lineLimit(2)
                }
            }.foregroundStyle(ink)
                .padding(.horizontal, compact ? 16 : 20)
                .padding(.vertical, compact ? 16 : 18)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
        }
    }
}
