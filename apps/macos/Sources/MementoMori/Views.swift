import SwiftUI
import AppKit
import MementoCore

func moriFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    let face = weight == .bold ? "Bold" : (weight == .semibold ? "SemiBold" : (weight == .medium ? "Medium" : "Regular"))
    return .custom("PretendardVariable-\(face)", size: size)
}

struct DragHandle: NSViewRepresentable {
    class Surface: NSView {
        override func mouseDown(with event: NSEvent) { window?.performDrag(with: event) }
    }
    func makeNSView(context: Context) -> Surface { Surface() }
    func updateNSView(_ nsView: Surface, context: Context) {}
}

// A visible grip complements the system resize regions of the borderless panel.
struct ResizeHandle: NSViewRepresentable {
    class Surface: NSView {
        override var mouseDownCanMoveWindow: Bool { false }
        override func resetCursorRects() { addCursorRect(bounds, cursor: .crosshair) }
        override func mouseDown(with event: NSEvent) {
            guard let window else { return }
            let original = window.frame
            let start = NSEvent.mouseLocation
            let screen = window.screen?.visibleFrame
            while let next = window.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) {
                if next.type == .leftMouseUp { break }
                let point = NSEvent.mouseLocation
                let maxWidth = min(window.maxSize.width, (screen?.maxX ?? original.maxX + 1200) - original.minX)
                let maxHeight = min(window.maxSize.height, original.maxY - (screen?.minY ?? 0))
                let width = max(window.minSize.width, min(maxWidth, original.width + point.x - start.x))
                let height = max(window.minSize.height, min(maxHeight, original.height - point.y + start.y))
                window.setFrame(NSRect(x: original.minX, y: original.maxY - height, width: width, height: height), display: true)
            }
            window.delegate?.windowDidEndLiveResize?(Notification(name: NSWindow.didEndLiveResizeNotification, object: window))
        }
    }
    func makeNSView(context: Context) -> Surface { Surface() }
    func updateNSView(_ nsView: Surface, context: Context) {}
}

struct WidgetView: View {
    @ObservedObject var store: Store
    let showSettings: () -> Void
    @State private var hovered = false
    private var variant: Variant { store.settings.widget.variant }
    private var dark: Bool { store.settings.widget.theme == .dark }
    private var fg: Color { dark ? Color(white: 0.97) : Color(white: 0.09) }
    private var bg: Color { dark ? Color(white: 0.082) : Color(white: 0.98) }
    private var muted: Color { dark ? Color(white: 0.65) : Color(white: 0.4) }
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let compact = height < 150
            let padding: CGFloat = compact ? 16 : min(32, max(20, width * 0.065))
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let profile = store.settings.state.profile ?? .example
                let snapshot = try? Life.snapshot(profile, now: context.date)
                let demo = store.settings.state.profile == nil
                let intention = store.settings.state.intention
                VStack(alignment: .leading, spacing: compact ? 4 : 8) {
                    if !compact {
                        Text("mementomori.").font(moriFont(11, weight: .bold))
                    }
                    if height < 250 && width >= 280 {
                        HStack(spacing: 12) {
                            scene(snapshot).frame(width: width * 0.27)
                            VStack(alignment: .leading, spacing: 6) {
                                caption(snapshot, demo: demo).font(moriFont(compact ? 8 : 10))
                                number(snapshot, size: min(48, (width - padding * 2) * 0.075))
                                if !compact { Text(store.scene.message).font(moriFont(10)).foregroundStyle(muted).fixedSize(horizontal: false, vertical: true) }
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }.frame(maxHeight: .infinity)
                    } else if compact {
                        caption(snapshot, demo: demo).font(moriFont(8))
                        number(snapshot, size: 22)
                    } else {
                        scene(snapshot).frame(maxWidth: .infinity, maxHeight: .infinity)
                        caption(snapshot, demo: demo).font(moriFont(width < 250 ? 8 : 10))
                        number(snapshot, size: min(72, (width - padding * 2) * 0.12))
                        if height >= 280 {
                            Text(store.scene.message).font(moriFont(11)).foregroundStyle(muted).fixedSize(horizontal: false, vertical: true)
                            if intention?.date == Life.dayKey(context.date), let text = intention?.text, !text.isEmpty {
                                Text(text).font(moriFont(10)).foregroundStyle(muted).lineLimit(2)
                            }
                        }
                    }
                    horizon(snapshot?.progress ?? 0)
                }
                .padding(padding)
                .frame(width: width, height: height, alignment: .topLeading)
                .foregroundStyle(fg).background(bg)
                .clipShape(RoundedRectangle(cornerRadius: compact ? 14 : 20))
                .overlay(RoundedRectangle(cornerRadius: compact ? 14 : 20).strokeBorder(fg.opacity(0.12)))
                .overlay(alignment: .topLeading) {
                    DragHandle().frame(width: max(0, width - 50), height: compact ? 25 : 40).padding(.leading, 8).help("드래그하여 위치 이동")
                }
                .overlay(alignment: .topTrailing) {
                    Button(action: showSettings) { Image(systemName: "ellipsis").frame(width: 28, height: 24).contentShape(Rectangle()) }
                        .buttonStyle(.plain).foregroundStyle(muted).background(bg).clipShape(Capsule())
                        .padding(8).opacity(hovered ? 1 : 0).accessibilityLabel("메멘토모리 설정")
                }
                .overlay(alignment: .bottomTrailing) {
                    ResizeHandle().frame(width: 22, height: 22).help("드래그하여 크기 조절")
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "line.3.horizontal.decrease").font(.system(size: 9)).rotationEffect(.degrees(-45))
                                .foregroundStyle(muted).opacity(hovered ? 0.9 : 0.4).padding(5).allowsHitTesting(false).accessibilityHidden(true)
                        }
                }
                .onHover { hovered = $0 }
                .contextMenu {
                    ForEach(TimeScene.allCases) { scene in
                        Button(scene.title) { store.scene = scene }
                    }
                    Divider()
                    Toggle("모션", isOn: $store.motionEnabled)
                    Button("설정…", action: showSettings)
                }
            }
        }
    }
    private func scene(_ snapshot: Snapshot?) -> some View {
        TimeSceneView(scene: store.scene, progress: snapshot?.progress ?? 0, years: (store.settings.state.profile ?? .example).years, ink: fg, background: bg, motionEnabled: store.motionEnabled && store.widgetVisible).id(store.scene)
    }
    private func caption(_ snapshot: Snapshot?, demo: Bool) -> some View {
        return Text(snapshot == nil ? "기기 날짜를 확인해 주세요" : "\(demo ? "예시 · " : "")\(snapshot!.passed ? "오늘도, 당신의 시간입니다." : "당신의 시간은 유한합니다.")")
            .foregroundStyle(muted).lineLimit(1)
    }
    private func number(_ snapshot: Snapshot?, size: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: variant == .slim ? 4 : 7) {
            Text(snapshot.map { $0.seconds.formatted(.number.locale(Locale(identifier: "ko_KR"))) } ?? "—")
                .font(moriFont(size, weight: .medium)).monospacedDigit().tracking(-0.6).lineLimit(1).minimumScaleFactor(0.5)
            Text("초").font(moriFont(variant == .slim ? 8 : 10)).foregroundStyle(muted)
        }
        .accessibilityElement(children: .combine)
        .help("\((store.settings.state.profile ?? .example).years.formatted(.number.locale(Locale(identifier: "ko_KR"))))세까지 남은 시간 · 설정한 나이를 기준으로 계산하며 개인의 수명 예측이 아닙니다.")
    }
    private func horizon(_ progress: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().fill(fg).frame(height: 1)
                Rectangle().fill(dark ? Color(white: 0.38) : Color(white: 0.72)).frame(width: geometry.size.width * progress, height: 1)
                Circle().fill(fg).frame(width: 5, height: 5).background(Circle().fill(bg).frame(width: 11, height: 11)).offset(x: geometry.size.width * progress - 2.5)
                Rectangle().fill(fg).frame(width: 1, height: 5).offset(x: geometry.size.width - 1)
            }.frame(height: 5)
        }.frame(height: 5).accessibilityLabel("지나온 삶 \(Int(progress * 100))퍼센트")
    }
}

struct SettingsView: View {
    @ObservedObject var store: Store
    let showWidget: () -> Void
    @State private var birthday = ""
    @State private var years = "83.7"
    @State private var thought = ""
    @State private var error = ""
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 9) {
                    Text("mementomori.").font(moriFont(14, weight: .bold))
                    Text("당신의 시간,\n일상 한편에.").font(moriFont(32, weight: .bold)).lineSpacing(2)
                    Text("설정은 이 Mac에만 저장됩니다.").foregroundStyle(.secondary)
                }
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("생년월일")
                            TextField("YYYY-MM-DD", text: $birthday).accessibilityLabel("생년월일")
                        }
                        VStack(alignment: .leading, spacing: 7) {
                            Text("기준 수명 · 세")
                            TextField("83.7", text: $years).accessibilityLabel("기준 수명")
                        }.frame(width: 110)
                    }
                    Text("83.7세 · 대한민국 2024년 출생 시 기대수명.\n개인의 수명 예측이 아닌, 오늘을 기억하는 가늠자입니다.")
                        .font(moriFont(11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Text("오늘의 한 문장")
                    TextField("오늘을 기억할 나만의 문장", text: $thought).accessibilityLabel("오늘의 한 문장")
                    if !error.isEmpty { Text(error).font(moriFont(12)).accessibilityLabel("오류: \(error)") }
                    Button("나의 시간 저장") { saveProfile() }.buttonStyle(.borderedProminent).tint(.black)
                }
                Divider()
                VStack(alignment: .leading, spacing: 12) {
                    Text("시간을 바라보는 방식").font(moriFont(15, weight: .semibold))
                    Picker("시간 테마", selection: $store.scene) {
                        ForEach(TimeScene.allCases) { Text($0.title).tag($0) }
                    }
                    TimeSceneView(scene: store.scene, progress: (try? Life.snapshot(store.settings.state.profile ?? .example))?.progress ?? 0, years: (store.settings.state.profile ?? .example).years, ink: .black, background: Color(white: 0.98), motionEnabled: store.motionEnabled).frame(height: 160)
                    Text(store.scene.message).font(moriFont(12))
                    Text("그림을 클릭하면 \(store.scene.action). 시간 카운트는 계속 흐릅니다.").font(moriFont(11)).foregroundStyle(.secondary)
                    Toggle("모션 켜기", isOn: $store.motionEnabled)
                    Text("시스템의 동작 줄이기 설정도 따릅니다.").font(moriFont(11)).foregroundStyle(.secondary)
                    Text("곁에 둘 모습").font(moriFont(15, weight: .semibold))
                    Picker("형태", selection: $store.settings.widget.variant) {
                        ForEach(Variant.allCases, id: \.self) { Text($0.label).tag($0) }
                    }.pickerStyle(.segmented)
                    Picker("테마", selection: $store.settings.widget.theme) {
                        Text("다크").tag(Theme.dark); Text("라이트").tag(Theme.light)
                    }.pickerStyle(.segmented)
                    Text("윗부분을 드래그하면 이동하고, 가장자리나 오른쪽 아래 모서리를 드래그하면 크기가 바뀝니다. 메뉴바에서 기본 크기로 되돌릴 수 있어요.")
                        .font(moriFont(11)).foregroundStyle(.secondary)
                }
                Divider()
                VStack(alignment: .leading, spacing: 10) {
                    Text("웹과 설정 옮기기").font(moriFont(15, weight: .semibold))
                    Text("설정 파일로 생년월일과 디자인을 옮깁니다. 자동으로 동기화되지는 않아요.")
                        .font(moriFont(11)).foregroundStyle(.secondary)
                    HStack {
                        Button("설정 가져오기") { store.importFile(); loadDraft() }
                        Button("설정 내보내기") { store.exportFile() }
                    }
                    if !store.message.isEmpty { Text(store.message).font(moriFont(12)).textSelection(.enabled) }
                }
                Button("이 Mac의 기록 지우기") { if store.resetProfile() { loadDraft() } }
                    .buttonStyle(.plain).font(moriFont(11)).foregroundStyle(.secondary)
                HStack {
                    Link("계산 기준 원문 ↗", destination: URL(string: "https://www.kostat.go.kr/boardDownload.es?bid=208&list_no=439533&seq=1")!).foregroundStyle(.secondary)
                    Spacer()
                    Button("작은 창 보기", action: showWidget)
                }.font(moriFont(11))
            }.padding(30)
        }
        .font(moriFont(13)).textFieldStyle(.roundedBorder).background(Color(white: 0.98))
        .preferredColorScheme(.light)
        .onAppear { loadDraft() }
        .onChange(of: store.settings.widget.variant) { _ in store.save() }
        .onChange(of: store.settings.widget.theme) { _ in store.save() }
    }
    private func loadDraft() {
        birthday = store.settings.state.profile?.birthday ?? ""
        years = String(store.settings.state.profile?.years ?? 83.7)
        thought = store.settings.state.intention?.date == Life.dayKey() ? store.settings.state.intention?.text ?? "" : ""
        error = ""
    }
    private func saveProfile() {
        do {
            let profile = Profile(birthday: birthday.trimmingCharacters(in: .whitespaces), years: Double(years) ?? .nan)
            try Life.validate(profile)
            guard thought.utf16.count <= 100 else { throw LifeError.invalid("오늘의 문장은 100자 이내로 입력해 주세요.") }
            store.settings.state.profile = profile
            let text = thought.trimmingCharacters(in: .whitespacesAndNewlines)
            store.settings.state.intention = text.isEmpty ? nil : Intention(text: text, date: Life.dayKey())
            store.save(); error = ""; store.message = "당신의 시간을 저장했어요."; showWidget()
        } catch { self.error = error.localizedDescription }
    }
}
