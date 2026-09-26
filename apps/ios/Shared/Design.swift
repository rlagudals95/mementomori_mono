import SwiftUI
import CoreText
import UIKit
import MementoCore

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
    var setupMessage = "길게 눌러 나의 시간을 설정하세요."
    private var ink: Color { dark ? Design.paper : Design.ink }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            HStack {
                Text("mementomori.").font(Design.font(11, weight: .bold))
                Spacer(minLength: 0)
                Text("M / M").font(Design.font(9)).opacity(0.55)
            }
            Spacer(minLength: 0)
            if let snapshot {
                Text((example ? "예시 · " : "") + (snapshot.passed ? "오늘도, 당신의 시간입니다." : "당신의 시간은 유한합니다."))
                    .font(Design.font(compact ? 10 : 12)).opacity(0.65).lineLimit(1).minimumScaleFactor(0.75)
                if snapshot.passed {
                    Text("오늘").font(Design.font(compact ? 34 : 46, weight: .bold))
                } else if timer {
                    Text(timerInterval: min(timerStart, date)...snapshot.end, countsDown: true, showsHours: true)
                        .font(Design.font(compact ? 26 : 38, weight: .bold)).monospacedDigit()
                        .lineLimit(1).minimumScaleFactor(0.4)
                    Text("시간 : 분 : 초").font(Design.font(9)).opacity(0.6)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(Design.number(snapshot.days)).font(Design.font(compact ? 34 : 46, weight: .bold)).monospacedDigit()
                            .lineLimit(1).minimumScaleFactor(0.5)
                        Text("일").font(Design.font(12)).opacity(0.6)
                    }
                }
                Spacer(minLength: 0)
                LifeLine(progress: snapshot.progress, color: ink)
                if !compact {
                    HStack(alignment: .top) {
                        Text(snapshot.passed ? "오늘도 삶은 계속됩니다." : (message.isEmpty ? "오늘은 다시 오지 않습니다." : message))
                            .font(Design.font(11)).lineLimit(2)
                        Spacer(minLength: 8)
                        Text("\(Int(snapshot.progress * 100))%")
                            .font(Design.font(10)).opacity(0.5).accessibilityLabel("지나온 \(Int(snapshot.progress * 100))퍼센트")
                    }
                }
            } else {
                Text(invalid ? "설정을 확인해 주세요." : "당신의 시간은\n유한합니다.")
                    .font(Design.font(compact ? 22 : 26, weight: .bold))
                Spacer(minLength: 0)
                Text(invalid ? "생년월일과 기준 나이를 확인해 주세요." : setupMessage)
                    .font(Design.font(11)).opacity(0.65)
            }
        }.foregroundStyle(ink).padding(compact ? 16 : 20)
    }
}
