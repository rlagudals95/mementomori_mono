import SwiftUI
import MementoCore
import MementoScenes

struct HomeView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = false
    @State private var showWidgets = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    HStack {
                        Text("mementomori.").font(Design.font(24, weight: .bold)).tracking(-1)
                        Spacer()
                        Button { showSettings = true } label: { Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44) }
                            .accessibilityLabel("나의 시간 설정")
                    }
                    if let profile = store.settings.state.profile {
                        dashboard(profile)
                    } else {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("언젠가 끝나기에,\n지금이 소중합니다.")
                                .font(Design.font(38, weight: .bold)).tracking(-1.5).fixedSize(horizontal: false, vertical: true)
                            Text("당신의 하루를 무한한 것처럼\n흘려보내지 않도록.")
                                .font(Design.font(16)).foregroundStyle(.secondary).lineSpacing(5)
                            WidgetFace(snapshot: nil, date: Date(), timerStart: Date(), setupMessage: "한 번뿐인 시간을 기억하세요.")
                                .frame(height: 210).background(Design.ink)
                            Button("나의 시간 시작하기") { showSettings = true }
                                .buttonStyle(PrimaryButton()).accessibilityIdentifier("start")
                            Text("생년월일은 이 iPhone에만 저장됩니다.")
                                .font(Design.font(12)).foregroundStyle(.secondary)
                        }.padding(.top, 12)
                    }
                    Button { showWidgets = true } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("일상에 시간을 놓아두세요.").font(Design.font(18, weight: .bold))
                                Text("홈 화면 · 잠금화면 위젯").font(Design.font(12)).foregroundStyle(.secondary)
                            }
                            Spacer(); Image(systemName: "arrow.up.right")
                        }.padding(.vertical, 22)
                    }.overlay(alignment: .top) { Rectangle().frame(height: 1) }
                    Text("죽음을 기억하라. 오늘을 살아라.")
                        .font(Design.font(11)).foregroundStyle(.secondary).padding(.bottom, 16)
                }.padding(24).frame(maxWidth: 620)
            }.background(Design.paper).toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $showSettings) { SettingsView().environmentObject(store) }
                .sheet(isPresented: $showWidgets) { WidgetGuide().environmentObject(store) }
                .onOpenURL { url in if url.scheme == "mementomori", url.host == "widget-help" { showWidgets = true } }
        }
    }

    private func dashboard(_ profile: Profile) -> some View {
        TimelineView(.periodic(from: Date(), by: 1)) { context in
            if let snapshot = try? Life.snapshot(profile, now: context.date) {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("나의 시간").font(Design.font(12)).foregroundStyle(.secondary)
                        Spacer()
                        Picker("표시 단위", selection: Binding(get: { store.settings.state.mode }, set: store.mode)) {
                            Text("초").tag("seconds"); Text("일").tag("days")
                        }.pickerStyle(.segmented).frame(width: 110)
                    }
                    Picker("시간 테마", selection: $store.scene) {
                        ForEach(TimeScene.allCases) { Text($0.title).tag($0) }
                    }.font(Design.font(14)).accessibilityIdentifier("scene-picker")
                    VStack(alignment: .leading, spacing: 24) {
                        TimeSceneView(scene: store.scene, progress: snapshot.progress, years: profile.years, ink: Design.paper, background: Design.ink, motionEnabled: store.motionEnabled && scenePhase == .active && !showSettings && !showWidgets)
                            .frame(height: 230).id(store.scene).accessibilityIdentifier("time-scene")
                        Text(snapshot.passed ? "오늘도, 당신의 시간입니다." : "당신의 시간은 유한합니다.")
                            .font(Design.font(14)).opacity(0.7)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(snapshot.passed ? "오늘" : Design.number(store.settings.state.mode == "days" ? snapshot.days : snapshot.seconds))
                                .font(Design.font(48, weight: .bold)).tracking(-2).monospacedDigit()
                                .lineLimit(1).minimumScaleFactor(0.35).accessibilityIdentifier("countdown")
                            if !snapshot.passed { Text(store.settings.state.mode == "days" ? "일" : "초").font(Design.font(13)).opacity(0.6) }
                        }
                        LifeLine(progress: snapshot.progress, color: Design.paper)
                        HStack {
                            Text(snapshot.passed ? "오늘도 삶은 계속됩니다." : (store.settings.state.intention?.date == Life.dayKey(context.date) ? Design.thought(store.settings, at: context.date) : store.scene.message)).font(Design.font(13))
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Text("\(snapshot.progress * 100, specifier: "%.1f")%")
                                .font(Design.font(11)).opacity(0.6).accessibilityLabel("지나온 삶의 비율")
                        }
                    }.padding(24).foregroundStyle(Design.paper).background(Design.ink)
                    Text("\(profile.years.formatted())세를 시간의 가늠자로 사용합니다. 개인의 수명 예측이 아닙니다.")
                        .font(Design.font(11)).foregroundStyle(.secondary).lineSpacing(3)
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("한 칸은, 일주일.").font(Design.font(20, weight: .bold))
                            Spacer()
                            Text("\(Int(snapshot.progress * 100))%를 살아왔습니다.").font(Design.font(10)).foregroundStyle(.secondary)
                        }
                        WeekGrid(profile: profile, progress: snapshot.progress)
                        Text("채워진 시간 · 오늘의 자리 · 앞으로의 시간")
                            .font(Design.font(10)).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct WeekGrid: View {
    let profile: Profile
    let progress: Double
    var body: some View {
        let weeks = Int(ceil(profile.years * 365.2425 / 7))
        let rows = Int(ceil(Double(weeks) / 52))
        Canvas { context, size in
            let step = size.width / 52
            for index in 0..<weeks {
                let rect = CGRect(x: CGFloat(index % 52) * step, y: CGFloat(index / 52) * step, width: max(1, step - 2), height: max(1, step - 2))
                let passed = index < Int(Double(weeks) * progress)
                let current = index == Int(Double(weeks) * progress)
                let path = Path(ellipseIn: rect)
                if current { context.stroke(path, with: .color(Design.ink), lineWidth: 1) }
                else { context.fill(path, with: .color(passed ? Design.ink : Design.ink.opacity(0.12))) }
            }
        }.aspectRatio(52 / CGFloat(rows), contentMode: .fit)
            .accessibilityLabel("삶의 주간 달력, \(Int(progress * 100))퍼센트를 지나왔습니다.")
    }
}

struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(Design.font(15, weight: .bold))
            .frame(maxWidth: .infinity).padding(.vertical, 18)
            .foregroundStyle(Design.paper).background(Design.ink.opacity(configuration.isPressed ? 0.7 : 1))
    }
}
